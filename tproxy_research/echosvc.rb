#!/usr/bin/env ruby

$stdout.sync = true

require 'async/io'
require 'async/io/stream'
require 'socket'

class EchoSvc

    def initialize(addr = '0.0.0.0', port = 3640, listen = Socket::SOMAXCONN)
        @endpoint = Async::IO::Endpoint.tcp(addr, port)
        @listen = listen
    end

    def run
        Async do |task|
            @endpoint.accept do |peer|
                Console.logger.debug(self) {"Accepting #{peer.remote_address.inspect}"}

                stream = Async::IO::Stream.new(peer)

                task.async do
                    while chunk = stream.read_partial
                        stream.write 'ECHO: '
                        stream.write chunk
                        stream.flush
                    end
                end.wait

                Console.logger.debug(self) {"Closing #{peer.remote_address.inspect}"}
                peer.close
            end
        end
    end

end

if caller.empty?
    service = EchoSvc.new
    service.run
end
