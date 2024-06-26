#!/usr/bin/env python3

def iptables_cmd(args, table = 'nat', command = '-I', chain = 'POSTROUTING'):
    _check = f"iptables-nft -t {table} -C {chain} {args}"
    _apply = f"iptables-nft -t {table} {command} {chain} {args}"
    return f"{_check} || {_apply}"

def ip_rule_replace_cmd(args):
    _check = f"[ -n \"$(ip rule list {args})\" ]"
    _apply = f"ip rule add {args}"
    return f"{_check} || {_apply}"

class FilterModule(object):
    def filters(self):
        return {
            'iptables_cmd': iptables_cmd,
            'ip_rule_replace_cmd': ip_rule_replace_cmd,
        }

if __name__ == '__main__':
    print(iptables_cmd('asd'))
    print(ip_rule_replace_cmd('asd'))
