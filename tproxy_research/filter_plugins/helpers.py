#!/usr/bin/env python3

import base64

def identity(x):
    return x

def iptables_cmd(args, table = 'nat', command = '-I', chain = 'POSTROUTING'):
    _check = f"iptables-nft -t {table} -C {chain} {args}"
    _apply = f"iptables-nft -t {table} {command} {chain} {args}"
    return f"{_check} || {_apply}"

def ip_rule_replace_cmd(args):
    _check = f"[ -n \"$(ip rule list {args})\" ]"
    _apply = f"ip rule add {args}"
    return f"{_check} || {_apply}"

def ip_route_replace_cmd(args):
    return f"ip route replace {args}"

def nft_cmd(args):
    encoded = base64.b64encode(args.encode()).decode()
    return f"echo '{encoded}' | base64 -d | nft -f-"

class FilterModule(object):
    def filters(self):
        return {
            'identity': identity,
            'iptables_cmd': iptables_cmd,
            'ip_rule_replace_cmd': ip_rule_replace_cmd,
            'ip_route_replace_cmd': ip_route_replace_cmd,
            'nft_cmd': nft_cmd,
        }

if __name__ == '__main__':
    print(identity('asd'))
    print(iptables_cmd('asd'))
    print(ip_rule_replace_cmd('asd'))
    print(ip_route_replace_cmd('asd'))
    print(nft_cmd('asd'))
