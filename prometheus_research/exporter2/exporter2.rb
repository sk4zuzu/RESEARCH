#!/usr/bin/env ruby

require 'socket'
require 'sinatra'
require 'prometheus/middleware/exporter'
require 'prometheus/middleware/collector'

class AsdCollector < Prometheus::Middleware::Collector
    HOST = Addrinfo.getaddrinfo(Socket.gethostname, nil).first.getnameinfo.first

    def initialize(app)
        super(app, :metrics_prefix => 'asd')

        @asd_up = @registry.gauge(
            :asd_up,
            :docstring => 'asd_up',
            :labels    => [ :host ]
        )
        @asd_nil = @registry.gauge(
            :asd_nil,
            :docstring => 'asd_nil',
            :labels    => [ :host ]
        )

        @asd_asd = @registry.gauge(
            :asd_asd,
            :docstring => 'asd_asd',
            :labels    => []
        )
    end

    def record(env, code, duration)
        super(env, code, duration)

        @asd_up.set(0, :labels => { :host => HOST })
        @asd_nil.set(0, :labels => { :host => HOST })

        @asd_asd.set(86)
    end
end

use Rack::Deflater
use AsdCollector
use Prometheus::Middleware::Exporter

get '/' do
    body = '<html>'\
           '<head><title>Exporter2</title></head>'\
           '<body>'\
           '<h1>Exporter2</h1>'\
           '<p><a href="/metrics">Metrics</a></p>'\
           '</body>'\
           '</html>'
    [200, { 'Content-Type' => 'text/html' }, body]
end

set :bind, '0.0.0.0'
set :port, 8686

set :run, false
Sinatra::Application.run! if caller.empty?
