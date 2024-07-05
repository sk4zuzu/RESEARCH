#!/usr/bin/env ruby

LOG_LOCATION = '/var/log'
RUN_LOCATION = '/var/run'

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
        def initialize(bport, daddr, dport)
            @proxy_ep    = Async::IO::Endpoint.socket setup_socket('127.0.0.1', bport, bport)
            @server_addr = daddr
            @server_port = dport
        end

        def run
            Async do |task|
                glue_peers task
            end
        end

        private

        def setup_socket(baddr, bport, mark, listen = Socket::SOMAXCONN)
            sock = Socket.new Socket::AF_INET, Socket::SOCK_STREAM, 0

            sock.setsockopt Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1
            sock.setsockopt Socket::SOL_SOCKET, Socket::SO_MARK, mark

            sock.setsockopt Socket::SOL_IP, Socket::IP_TRANSPARENT, 1

            $logger.info(self) do
                "Bind #{Addrinfo.tcp(baddr, bport).inspect}"
            end

            sock.bind Socket.pack_sockaddr_in(bport, baddr)
            sock.listen listen
            sock
        end

        def glue_streams(stream1, stream2, task)
            Async do
                concurrent = []
                concurrent << task.async do
                    while (chunk = stream1.read_partial)
                        $logger.debug(self) {"REQ: `#{chunk}`"}
                        stream2.write chunk
                        stream2.flush
                    end
                end
                concurrent << task.async do
                    while (chunk = stream2.read_partial)
                        $logger.debug(self) {"RSP: `#{chunk}`"}
                        stream1.write chunk
                        stream1.flush
                    end
                end
                concurrent.each(&:wait)
            end
        end

        def glue_peers(task)
            @proxy_ep.accept do |client_peer|
                $logger.debug(self) do
                    "Accept #{client_peer.remote_address.inspect}"
                end

                begin
                    server_ep = Async::IO::Endpoint.tcp @server_addr,
                                                        @server_port
                    server_ep.connect do |server_peer|
                        client_stream, server_stream = Async::IO::Stream.new(client_peer),
                                                       Async::IO::Stream.new(server_peer)

                        glue_streams(client_stream, server_stream, task).wait

                        $logger.debug(self) do
                            "Close #{server_peer.remote_address.inspect}"
                        end

                        server_peer.close
                    end
                rescue Errno::ECONNREFUSED,
                       Errno::ECONNRESET,
                       Errno::EHOSTUNREACH,
                       Errno::ETIMEDOUT => e
                        $logger.error(self) do
                            e.message
                        end
                end

                $logger.debug(self) do
                    "Close #{client_peer.remote_address.inspect}"
                end

                client_peer.close
            end
        end
    end

    class Multi
        def initialize
            @single = []
        end

        def add(port, daddr, dport)
            @single << Single.new(port, daddr, dport)
        end

        def run
            Async do
                @single.each do |single|
                    single.run
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

            @options[:app_name] = @app_name = "tproxy_#{$options[:brdev]}"
            @options[:dir]      = RUN_LOCATION
        end
    end

end

Daemons.run_proc(nil) do
    CustomLogger = Console::Filter[debug: 0, info: 1, warn: 2, error: 3]
    logfile      = File.open "#{LOG_LOCATION}/tproxy_#{$options[:brdev]}.json", 'a'
    logfile.sync = true
    serialized   = Console::Serialized::Logger.new logfile
    $logger      = CustomLogger.new serialized, level: 0

    if $options[:proxy].empty?
        $logger.error(self) {'At least single bport:daddr:dport triple must be provided.'}
        exit(-1)
    end

    multi = TProxy::Multi.new

    $options[:proxy].each do |item|
        multi.add item[:bport], item[:daddr], item[:dport]
    end

    multi.run
end
