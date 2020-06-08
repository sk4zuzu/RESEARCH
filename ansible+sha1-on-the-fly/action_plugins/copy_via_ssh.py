#!/usr/bin/env python

import copy

from ansible.errors import AnsibleError
from ansible.plugins.action import ActionBase
from ansible.utils.vars import merge_hash


class ActionModule(ActionBase):

    MANDATORY_ARGUMENTS = {"ssh_host", "path", "script"}

    OPTIONAL_ARGUMENTS = {"ssh_user", "ssh_key", "ssh_opts", "chunk_size", "become", "become_user", "become_method", "mode"}

    def __init__(self, *args, **kwargs):
        super(ActionModule, self).__init__(*args, **kwargs)
        self.module_args = dict()

    def collect_module_args(self, *, hostvars):
        """Populate arguments for the ansible module executed later."""

        # Collect ansible_host and ansible_user facts when available.
        ssh_host = self._task.args["ssh_host"]
        if ssh_host in hostvars:
            if "ansible_host" in hostvars[ssh_host]:
                self.module_args.update(
                    ssh_host = hostvars[ssh_host]["ansible_host"],
                )
            if "ansible_user" in hostvars[ssh_host]:
                self.module_args.update(
                    ssh_user = hostvars[ssh_host]["ansible_user"],
                )

        if self._connection.become:
            # Inherit the "become" info.
            self.module_args.update(
                become        = True,
                become_method = self._connection.become.name,
                become_user   = self._connection.become.get_option("become_user", playcontext=self._play_context),
            )

        # Merge the inferred arguments with arguments provided by the user.
        self.module_args.update(self._task.args)

    def validate_module_args(self):
        """Do a basic check if provided arguments are correct (full check should be performed inside the module)."""

        for argument in self.module_args:
            if argument not in self.MANDATORY_ARGUMENTS | self.OPTIONAL_ARGUMENTS:
                raise AnsibleError(f"invalid argument {argument}")

        for mandatory_argument in self.MANDATORY_ARGUMENTS:
            if mandatory_argument not in self.module_args:
                raise AnsibleError(f"missing argument {mandatory_argument}")

    def run(self, tmp=None, task_vars=None):
        """Execute the action plugin."""

        if task_vars is None:
            task_vars = dict()

        self.collect_module_args(hostvars=task_vars["hostvars"])
        self.validate_module_args()

        results = merge_hash(
            # Execute the run() helper method from the base class.
            super(ActionModule, self).run(tmp=tmp, task_vars=task_vars),

            # Execute the matching "copy_via_ssh" module on the remote host.
            self._execute_module(tmp=tmp, task_vars=task_vars, module_args=self.module_args),
        )

        return results


# vim:ts=4:sw=4:et:
