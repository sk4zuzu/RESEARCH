# frozen_string_literal: true

require 'async/io'
require 'async/io/stream'
require 'console'
require 'daemons'
require 'json'
require 'open3'
require 'resolv'
require 'socket'

LOG_LOCATION = '/var/log'
RUN_LOCATION = '/var/run'

$config = { :app_name => 'one_tproxy', :proxies => [] }
$logger = nil

module TProxy

    # A single async TCP transparent proxy implementation, it binds to a single port and
    # marks outgoing packets with SO_MARK.
    class Single

        def initialize(bport, daddr, dport, smark)
            @proxy_ep = Async::IO::Endpoint.socket setup_socket('127.0.0.1', bport, smark)
            @daddr    = daddr
            @dport    = dport
        end

        def run
            Async do |task|
                glue_peers task
            end
        end

        private

        def setup_socket(baddr, bport, smark, listen = Socket::SOMAXCONN)
            sock = Socket.new Socket::AF_INET, Socket::SOCK_STREAM, 0

            sock.setsockopt Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1
            sock.setsockopt Socket::SOL_SOCKET, Socket::SO_MARK, smark

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
                    server_ep = Async::IO::Endpoint.tcp @daddr,
                                                        @dport
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

    # Combine multiple proxies into one async service.
    class Multi

        def initialize
            @single = []
        end

        def add(bport, daddr, dport, smark)
            @single << Single.new(bport, daddr, dport, smark)
        rescue StandardError => e
            $logger.error(self) do
                e.message
            end
        end

        def run
            Async do
                # Run all proxies.
                @single.each(&:run)
            end
        end

    end

end

Daemons.run_proc($config[:app_name], :dir => RUN_LOCATION) do
    CustomLogger = Console::Filter[:debug => 0, :info => 1, :warn => 2, :error => 3]
    logfile      = File.open "#{LOG_LOCATION}/#{$config[:app_name]}.log", 'a'
    logfile.sync = true
    serialized   = Console::Serialized::Logger.new logfile
    $logger      = CustomLogger.new serialized, :level => 0

    o, e, s = Open3.capture3(*"nft --json list map ip #{$config[:app_name]} proxies".split(' '))

    unless s.success?
        $logger.error(self) {e}
        exit(-1)
    end

    $config[:proxies] = \
        JSON.parse(o)&.dig('nftables')
                     &.find { |item| !item['map'].nil? }
                     &.dig('map', 'elem')
                     &.map { |item| item.map(&:values).flatten }
                     .to_a

    if $config[:proxies].empty?
        $logger.error(self) {'No proxies defined.'}
        exit(-1)
    end

    multi = TProxy::Multi.new

    # type ifname . ipv4_addr . inet_service : inet_service . ipv4_addr . inet_service . mark;
    $config[:proxies].each do |_, _, _, bport, daddr, dport, smark|
        multi.add bport, daddr, dport, smark
    end

    multi.run
end
