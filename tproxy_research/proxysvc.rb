#!/usr/bin/env ruby

require 'async/io'
require 'async/io/stream'
require 'console'
require 'daemons'
require 'resolv'
require 'socket'

$options = {}
$logger  = nil

module TProxy

    class Single
        def initialize(port, daddr, dport)
            @endpoint = Async::IO::Endpoint.socket setup_socket('127.0.0.1', port, port)
            @daddr, @dport = daddr, dport
        end

        def run
            Async do |task|
                @endpoint.accept do |peer|
                    $logger.debug(self) {"Accepting #{peer.remote_address.inspect}"}

                    dendpoint = Async::IO::Endpoint.tcp(@daddr, @dport)

                    dendpoint.connect do |dpeer|
                        stream, dstream = Async::IO::Stream.new(peer), Async::IO::Stream.new(dpeer)

                        glue_streams(stream, dstream, task).wait

                        $logger.debug(self) {"Closing #{dpeer.remote_address.inspect}"}
                        dpeer.close
                    end

                    $logger.debug(self) {"Closing #{peer.remote_address.inspect}"}
                    peer.close
                end
            end
        end

        private

        def setup_socket(addr, port, mark, listen = Socket::SOMAXCONN)
            sock = Socket.new Socket::AF_INET, Socket::SOCK_STREAM, 0

            sock.setsockopt Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1
            sock.setsockopt Socket::SOL_SOCKET, Socket::SO_MARK, mark

            sock.setsockopt Socket::SOL_IP, Socket::IP_TRANSPARENT, 1

            $logger.debug(self) {"Binding to #{Addrinfo.tcp(addr, port).inspect}"}

            sock.bind Socket.pack_sockaddr_in(port, addr)
            sock.listen listen
            sock
        end

        def glue_streams(stream1, stream2, task)
            Async do
                concurrent = []
                concurrent << task.async do
                    while chunk = stream1.read_partial
                        $logger.debug(self) {"REQ: `#{chunk}`"}
                        stream2.write chunk
                        stream2.flush
                    end
                end
                concurrent << task.async do
                    while chunk = stream2.read_partial
                        $logger.debug(self) {"RSP: `#{chunk}`"}
                        stream1.write chunk
                        stream1.flush
                    end
                end
                concurrent.each(&:wait)
            end
        end
    end

    class Multi
        def initialize
            @proxy = []
        end

        def add(port, daddr, dport)
            @proxy << Single.new(port, daddr, dport)
        end

        def run
            Async do
                @proxy.each do |service|
                    service.run
                end
            end
        end
    end

end

module Daemons

    class Controller
        def setup_options
            $options[:brdev] = @app_part[0]

            raise StandardError, 'Bridge name must be provided.' \
                if $options[:brdev].nil?

            $options[:proxy] = @app_part[1..(-1)].to_a.each_with_object([]) do |triple, acc|
                bport, daddr, dport = triple.split(%[:])

                next if bport.nil? || daddr.nil? || dport.nil?

                acc << {
                    bport: Integer(bport),
                    daddr: Addrinfo.ip(daddr).ip_address,
                    dport: Integer(dport)
                }
            end

            @options[:app_name] = @app_name = "one_tproxy_#{$options[:brdev]}"
            @options[:dir]      = '/'
        end
    end

end

Daemons.run_proc(nil) do
    CustomLogger = Console::Filter[debug: 0, info: 1, warn: 2, error: 3]
    logfile      = File.open "/one_tproxy_#{$options[:brdev]}.json", 'a'
    logfile.sync = true
    serialized   = Console::Output::Serialized.new logfile
    $logger      = CustomLogger.new serialized, level: 0

    if $options[:proxy].empty?
        $logger.error(self) {'At least one bport:daddr:dport tuple must be provided.'}
        exit(-1)
    end

    service = TProxy::Multi.new

    $options[:proxy].each do |item|
        service.add item[:bport], item[:daddr], item[:dport]
    end

    service.run
end
