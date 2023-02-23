require 'json'
require 'open3'
require 'pathname'

SELF = Pathname.new(__FILE__).realpath.dirname

class RC
    attr_reader :stdout, :stderr, :code
    def initialize(*args)
        @stdout, @stderr, @code = *args
    end
end

def restic(cmd, args = {})
    args = args.to_a.map {|kv| %('--#{kv.compact.join('=').delete(%("'))}') }
    %(#{SELF/'.cache'/'restic'} #{cmd} #{args.join(' ')})
end

def run_action(_name, script, _host = nil)
    RC.new *Open3.capture3('/bin/bash -s', :stdin_data => script)
end

def get_snaps
    JSON.parse(run_action('snaps', <<~EOS).stdout).map {|item| item['short_id']}
        set -e -o pipefail; shopt -qs failglob
        #{restic('snapshots', 'no-lock' => nil, 'json' => nil)}
    EOS
end
