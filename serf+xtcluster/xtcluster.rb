#!/usr/bin/env ruby

require 'json'
require 'open3'
require 'socket'

CHPFX = 'asd'

NIC = 'eth0'
VIP = '10.2.20.86/24'
MAC = '01:00:fe:ed:ca:fe'

SEED = '0xfeedcafe'
MARK = '0xcafe'

def bash(script)
    command = 'exec /bin/bash --login -s'

    stdin_data = <<~SCRIPT
    set -o errexit -o nounset -o pipefail
    set -x
    #{script}
    SCRIPT

    stdout, stderr, status = Open3.capture3 command, stdin_data: stdin_data
    raise "#{status.exitstatus}: #{stderr}" unless status.exitstatus.zero?

    stdout
end

def setup_iproute
    bash(<<~SCRIPT)
        ip address replace '#{VIP}' dev '#{NIC}' label '#{NIC}:VIP'
    SCRIPT

    bash(<<~SCRIPT)
        ip maddress add '#{MAC}' dev '#{NIC}'
    SCRIPT
end

def setup_arptables
    bash(<<~SCRIPT)
        arptables -nL '#{CHPFX}-out' || arptables -N '#{CHPFX}-out'
        arptables -F '#{CHPFX}-out'
        arptables -C OUTPUT -j '#{CHPFX}-out' || arptables -A OUTPUT -j '#{CHPFX}-out'
    SCRIPT

    bash(<<~SCRIPT)
        arptables -A '#{CHPFX}-out' \
        -o '#{NIC}' \
        --h-length 6 \
        -s '#{VIP.split("/")[0]}' \
        -j mangle \
        --mangle-mac-s '#{MAC}'
    SCRIPT

    bash(<<~SCRIPT)
        arptables -nL '#{CHPFX}-in' || arptables -N '#{CHPFX}-in'
        arptables -F '#{CHPFX}-in'
        arptables -C INPUT -j '#{CHPFX}-in' || arptables -A INPUT -j '#{CHPFX}-in'
    SCRIPT

    doc = JSON.parse bash("ip --json address show dev '#{NIC}'")

    bash(<<~SCRIPT)
        arptables -A '#{CHPFX}-in' \
        -i '#{NIC}' \
        --h-length 6 \
        --destination-mac '#{MAC}' \
        -j mangle \
        --mangle-mac-d '#{doc[0]['address']}'
    SCRIPT
end

def setup_iptables
    bash(<<~SCRIPT)
        iptables -t mangle -nL '#{CHPFX}-pre' || iptables -t mangle -N '#{CHPFX}-pre'
        iptables -t mangle -F '#{CHPFX}-pre'
        iptables -t mangle -C PREROUTING -j '#{CHPFX}-pre' || iptables -t mangle -A PREROUTING -j '#{CHPFX}-pre'
    SCRIPT

    doc = JSON.parse bash('serf members -format=json')

    alive_members = doc['members'].select do |member|
        member['status'] == 'alive'
    end

    alive_members.sort! do |member1, member2|
        member1['name'] <=> member2['name']
    end

    total_nodes = alive_members.count

    hostname = Socket.gethostname.split('.')[0]

    local_node = alive_members.index do |member|
        member['name'] == hostname
    end + 1

    bash(<<~SCRIPT)
        iptables -t mangle -A '#{CHPFX}-pre' \
        -i '#{NIC}' \
        -p tcp -d '#{VIP.split('/')[0]}' \
        -m cluster \
        --cluster-total-nodes '#{total_nodes}' \
        --cluster-local-node '#{local_node}' \
        --cluster-hash-seed '#{SEED}' \
        -j MARK --set-mark '#{MARK}'
    SCRIPT

    bash(<<~SCRIPT)
        iptables -t mangle -A '#{CHPFX}-pre' \
        -i '#{NIC}' \
        -p tcp -d '#{VIP.split('/')[0]}' \
        -m mark \
        ! --mark '#{MARK}' \
        -j DROP
    SCRIPT
end

if caller.empty?
    setup_iproute
    setup_arptables
    setup_iptables
end
