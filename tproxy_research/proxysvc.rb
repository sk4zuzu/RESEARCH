#!/usr/bin/env ruby

$stdout.sync = true

require 'async/io'
require 'async/io/stream'
require 'socket'

class ProxySvc

    def initialize(addr = '127.0.0.1', port = 7777, daddr = '10.2.51.21', dport = 3640)
        @endpoint = Async::IO::Endpoint.socket setup_socket(addr, port)
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

    def setup_socket(addr, port, listen = Socket::SOMAXCONN)
        sock = Socket.new Socket::AF_INET, Socket::SOCK_STREAM, 0

        sock.setsockopt Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1
        sock.setsockopt Socket::SOL_SOCKET, Socket::SO_MARK, 0x21ee

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

if caller.empty?
    service = ProxySvc.new
    service.run
end
