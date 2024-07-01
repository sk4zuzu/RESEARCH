#!/usr/bin/env ruby

$stdout.sync = true

require 'async/io'
require 'async/io/stream'
require 'socket'

class ProxySock

    def initialize(port, daddr, dport)
        @endpoint = Async::IO::Endpoint.socket setup_socket('127.0.0.1', port, port)
        @daddr, @dport = daddr, dport
    end

    def run
        Async do |task|
            @endpoint.accept do |peer|
                Console.logger.debug(self) {"Accepting #{peer.remote_address.inspect}"}

                dendpoint = Async::IO::Endpoint.tcp(@daddr, @dport)

                dendpoint.connect do |dpeer|
                    stream, dstream = Async::IO::Stream.new(peer), Async::IO::Stream.new(dpeer)

                    glue_streams(stream, dstream, task).wait

                    Console.logger.debug(self) {"Closing #{dpeer.remote_address.inspect}"}
                    dpeer.close
                end

                Console.logger.debug(self) {"Closing #{peer.remote_address.inspect}"}
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

        Console.logger.debug(self) {"Binding to #{Addrinfo.tcp(addr, port).inspect}"}

        sock.bind Socket.pack_sockaddr_in(port, addr)
        sock.listen listen
        sock
    end

    def glue_streams(stream1, stream2, task)
        Async do
            concurrent = []
            concurrent << task.async do
                while chunk = stream1.read_partial
                    Console.logger.debug(self) {"REQ: `#{chunk}`"}
                    stream2.write chunk
                    stream2.flush
                end
            end
            concurrent << task.async do
                while chunk = stream2.read_partial
                    Console.logger.debug(self) {"RSP: `#{chunk}`"}
                    stream1.write chunk
                    stream1.flush
                end
            end
            concurrent.each(&:wait)
        end
    end

end

class ProxySvc

    def initialize
        @socks = []
    end

    def add(port, daddr, dport)
        @socks << ProxySock.new(port, daddr, dport)
    end

    def run
        Async do
            @socks.each do |sock|
                sock.run
            end
        end
    end

end

if caller.empty?
    service = ProxySvc.new
    service.add 7777, '10.2.51.21', 3640
    service.add 4321, '10.2.51.21', 3640
    service.run
end
