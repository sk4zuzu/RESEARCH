#!/usr/bin/env ruby

require 'socket'

$stdout.sync = true

# https://www.haproxy.com/documentation/hapee/latest/onepage/management/#9.3
def active_backends
    sock = UNIXSocket.new '/var/run/haproxy.sock'
    sock.puts 'show servers state'

    version = sock.readline.rstrip!
    raise 'haproxy runtime api :show servers state: unsupported version' unless version == '1'

    headers = sock.readline.rstrip!.split[1..]

    backends = {}
    while row = sock.readline.rstrip!
        next if row.empty?

        map = headers.zip(row.split).to_h

        (backends[map['be_name']] ||= {})[map['srv_name']] = map
    end
rescue EOFError
    backends
ensure
    sock.close
end

if caller.empty?
    pp active_backends
end
