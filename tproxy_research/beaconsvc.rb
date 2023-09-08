#!/usr/bin/env ruby

$stdout.sync = true

require 'async/io'
require 'async/io/stream'
require 'socket'

class BeaconSvc

    def initialize(addr = '169.254.16.9', port = 5030)
        @endpoint = Async::IO::Endpoint.tcp(addr, port)
        @message = Socket.gethostname
    end

    def run
        Async do |task|
            @endpoint.connect do |peer|
                stream = Async::IO::Stream.new(peer)
                loop do
                    task.sleep 1
                    stream.puts @message
                    Console.logger.debug(self) {"RSP: `#{stream.gets.inspect}`"}
                end
            end
        end
    end

end

if caller.empty?
    service = BeaconSvc.new
    service.run
end
