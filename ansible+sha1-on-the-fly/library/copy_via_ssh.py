#!/usr/bin/env python3

ANSIBLE_METADATA = {
    "metadata_version": "1.1",
    "status": ["preview"],
    "supported_by": "community",
}

DOCUMENTATION = r"""
module: copy_via_ssh
short_description: copy_via_ssh
author: MichałOpala (@sk4zuzu)
description:
"""

EXAMPLES = r"""
- name: Compress the /tmp/asd/ folder and save the tar.gz archive on the destination host
  copy_via_ssh:
    ssh_user: "{{ hostvars[destination_host].ansible_user }}"
    ssh_host: "{{ hostvars[destination_host].ansible_default_ipv4.address }}"
    path: "{{ destination_dir }}/asd.tar.gz"
    script: |
      tar czpf - /tmp/asd/
    ssh_key: "{{ private_key_path }}"
    ssh_opts: "-S none -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    chunk_size: "{{ (1024**2) | int }}"
    become: true
    become_user: root
    become_method: sudo
    mode: push

- copy_via_ssh:
    mode: push
    ssh_host: "{{ destination_host }}"
    ssh_key: "{{ private_key_path }}"
    path: "{{ destination_dir }}/urandom.dd"
    script: |
      exec dd if=/dev/urandom bs={{ 1024**2 }} count=8 oflag=dsync status=none

- copy_via_ssh:
    mode: pull
    ssh_host: "{{ destination_host }}"
    ssh_key: "{{ private_key_path }}"
    path: "{{ destination_dir }}/urandom.dd"
    script: |
      exec dd of=/tmp/urandom.dd oflag=dsync status=none
"""

RETURN = r"""
changed:
  type: bool
failed:
  type: bool
params:
  type: list
results:
  type: list
errors:
  type: list
checksum:
  type: str
"""


from ansible.module_utils.basic import AnsibleModule

import os
import copy
import asyncio
import hashlib


DEFAULT_CHUNK_SIZE = 1024**2  # 1 MiB


async def run_pipeline(*coroutines):
    """Create standard unix pipeline (interconnect processes using unnamed pipes)."""

    # Create M = N - 1 read/write unnamed pipe endpoint pairs.
    pipes = [
        os.pipe()
        for _ in range(1, len(coroutines))
    ]

    # Split pipe tuples into read/write descriptor lists.
    read_descriptors = [
        descriptor
        for descriptor, _ in pipes
    ]
    write_descriptors = [
        descriptor
        for _, descriptor in pipes
    ]

    # Combine coroutines and read/write pipe descriptors into:
    # coroutine1 coroutine2 coroutine3 ... coroutineN
    # None       read1      read2      ... readM
    # write1     write2     write3     ... None
    coroutine_stdin_stdout_triples = zip(
        coroutines,
        [None, *read_descriptors],
        [*write_descriptors, None],
    )

    # Run all coroutines concurrently and collect results.
    results = await asyncio.gather(*[
        coroutine(
            stdin=stdin,
            stdout=stdout,
        )
        for coroutine, stdin, stdout in coroutine_stdin_stdout_triples
    ])

    # Remove "falsy" items from coroutine results.
    results_filtered = [
        result
        for result in results
        if isinstance(result, dict)
        if result["returncode"] or result["stderr"] or result["command"]
    ]

    return results_filtered


def run_shell(command):
    """Create an async shell command coroutine for a specific command string."""

    async def coroutine(command=command, *, stdin=None, stdout=None):
        try:
            # The stdin/stdout variables are supposed to be file descriptors obtained from the os.pipe() call.
            process = await asyncio.create_subprocess_shell(
                command,
                stdin=stdin,
                stdout=stdout,
                stderr=asyncio.subprocess.PIPE,
            )

            # Wait for coroutine to complete and capture its stderr output.
            _, stderr_output = await process.communicate()

        finally:
            # Close the stdin/stdout pipe descriptors (cleanup).
            if stdin is not None:
                os.close(stdin)
            if stdout is not None:
                os.close(stdout)

        # Return coroutine result document.
        return dict(
            returncode = int(process.returncode),
            stderr     = stderr_output,
            command    = command,
        )

    return coroutine


def map_chunks(function, *, chunk_size=DEFAULT_CHUNK_SIZE):
    """Create an async coroutine for mapping a specific function over the stream."""

    async def coroutine(function=function, *, chunk_size=chunk_size, stdin=None, stdout=None):
        # Assert that the coroutine is used only as an in-between map/filter.
        assert stdin is not None and stdout is not None

        loop = asyncio.get_event_loop()

        # Prepare reader object for a single thread async data processing.
        reader = asyncio.StreamReader(loop=loop)

        reader_protocol = asyncio.StreamReaderProtocol(reader, loop=loop)

        await loop.connect_read_pipe(
            lambda: reader_protocol,
            os.fdopen(stdin, "rb"),
        )

        # Prepare writer object for a single thread async data processing.
        writer_protocol = asyncio.StreamReaderProtocol(asyncio.StreamReader(loop=loop), loop=loop)

        writer_transport, _ = await loop.connect_write_pipe(
            lambda: writer_protocol,
            os.fdopen(stdout, "wb"),
        )

        writer = asyncio.StreamWriter(writer_transport, writer_protocol, None, loop=loop)

        # Process the data.
        try:
            while not reader.at_eof():
                chunk = await reader.read(n=chunk_size)
                if chunk:
                    writer.write(function(chunk))
        finally:
            writer.close()

    return coroutine


def derive_checksum(*, chunk_size=DEFAULT_CHUNK_SIZE, hashlib_object):
    """Create an async coroutine to calculate checksum on-the-fly."""

    def function(chunk, *, hashlib_object=hashlib_object):
        hashlib_object.update(chunk)
        return chunk

    return map_chunks(function, chunk_size=chunk_size)


async def async_main(params, *, hashlib_object):
    """Entrypoint for all async processing."""

    # Clone and extend "params" to use it as a common namespace for format() calls.
    params = copy.deepcopy(params)
    params.update(
        _ssh_key = "-i {ssh_key}".format(**params) if params["ssh_key"] else "",
        _become  = "{become_method} -u {become_user}".format(**params) if params["become"] else "",
    )

    if params["mode"] == "pull":
        return await run_pipeline(
            # Execute remote ssh command to save stdout to the destination file.
            run_shell("exec ssh {ssh_opts} {_ssh_key} {ssh_user}@{ssh_host} -- {_become} dd if={path} oflag=dsync status=none".format(**params)),

            # Calculate checksum on-the-fly and pass untouched data.
            derive_checksum(hashlib_object=hashlib_object),

            # Execute the custom script provided by users.
            run_shell(params["script"]),
        )

    if params["mode"] == "push":
        return await run_pipeline(
            # Execute the custom script provided by users.
            run_shell(params["script"]),

            # Calculate checksum on-the-fly and pass untouched data.
            derive_checksum(hashlib_object=hashlib_object),

            # Execute remote ssh command to save stdout to the destination file.
            run_shell("exec ssh {ssh_opts} {_ssh_key} {ssh_user}@{ssh_host} -- {_become} dd of={path} oflag=dsync status=none".format(**params)),
        )


def copy_via_ssh():
    """Entrypoint for the ansible module."""

    module = AnsibleModule(
        argument_spec = dict(
            ssh_user      = dict(required=True, type="str"),
            ssh_host      = dict(required=True, type="str"),
            path          = dict(required=True, type="str"),
            script        = dict(required=True, type="str"),
            ssh_key       = dict(required=False, type="str", default=""),
            ssh_opts      = dict(required=False, type="str", default="-S none -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"),
            chunk_size    = dict(required=False, type="int", default=DEFAULT_CHUNK_SIZE),
            become        = dict(required=False, type="bool", default=False),
            become_user   = dict(required=False, type="str", default="root"),
            become_method = dict(required=False, type="str", default="sudo", choices=["sudo"]),
            mode          = dict(required=False, type="str", default="push", choices=["pull", "push"])
        ),
    )

    # Create sha1 object to "accumulate" the checksum along the way.
    sha1 = hashlib.sha1()

    # Execute async processing.
    loop = asyncio.get_event_loop()
    results = loop.run_until_complete(async_main(module.params, hashlib_object=sha1))

    # Collect failed results from the pipeline execution.
    errors = [
        result
        for result in results
        if result["returncode"]  # non-zero
    ]

    failed = bool(errors)

    module.exit_json(
        changed  = True,
        failed   = failed,
        params   = module.params,
        results  = results,
        errors   = errors,
        checksum = None if failed else sha1.hexdigest(),
    )


if __name__ == "__main__":
    copy_via_ssh()


# vim:ts=4:sw=4:et:syn=python:
