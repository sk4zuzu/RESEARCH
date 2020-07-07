#!/usr/bin/env python3

import os
import re
import textwrap
import pathlib
import asyncio

from sanic import Sanic
from sanic.log import logger
from sanic.response import empty, text


COUNT_MIN = 1
COUNT_MAX = 4
QUEUE_MAX = 1

ENV_NAME = os.getenv("ENV_NAME", "kub1")

TERRAGRUNT_HCL = pathlib.Path("LIVE") / ENV_NAME / "terragrunt.hcl"

app = Sanic(name="RESEARCH")


async def _run_shell(command):
    process = await asyncio.create_subprocess_shell(command)
    returncode = await process.wait()
    return returncode


def _set_compute_count(count, path=TERRAGRUNT_HCL):
    with path.open("r") as stream:
        content = stream.read()

    content = "\n".join(
        re.sub(
            f'compute_count\s*=\s*\d*',
            f'compute_count = {count}',
            line,
        )
        for line in content.splitlines()
    )

    with path.open("w") as stream:
        stream.write(content)


async def _worker(queue):
    while True:
        count = await queue.get()
        logger.info("count = %d", count)

        _set_compute_count(count)

        command = textwrap.dedent(f"""
        make confirm apply-{ENV_NAME}
        """).strip()

        returncode = await _run_shell(command)
        logger.info("returncode = %d", returncode)


@app.route("/scale/<count>")
async def _scale(request, count):
    count = int(count)

    if COUNT_MIN > count or count > COUNT_MAX:
        return empty(status=400)

    queue = request.app.queue

    try:
        queue.put_nowait(count)
        return text(f"{queue.qsize()} / {queue.maxsize}", status=202)
    except asyncio.queues.QueueFull:
        return text(f"{queue.qsize()} / {queue.maxsize}", status=409)


@app.route("/favicon.ico")
async def _favicon(_):
    return empty(status=404)


@app.route("/")
async def _root(request):
    queue = request.app.queue
    return text(f"{queue.qsize()} / {queue.maxsize}", status=200)


@app.listener("after_server_start")
def _create_task_queue(app, loop):
    app.queue = asyncio.Queue(loop=loop, maxsize=QUEUE_MAX)
    app.add_task(_worker(app.queue))


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8686)

# vim:ts=4:sw=4:et:syn=python:
