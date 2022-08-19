#!/usr/bin/env ruby

$stdout.sync = true

require 'async/io'
require 'async/io/stream'

class BeaconSvc

    def initialize(addr = '169.254.169.254', port = 5030)
        @endpoint = Async::IO::Endpoint.tcp(addr, port)
    end

    def run
        Async do |task|
            @endpoint.connect do |peer|
                stream = Async::IO::Stream.new(peer)
                loop do
                    task.sleep 1
                    stream.puts 'asd'
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
