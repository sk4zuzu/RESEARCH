#!/usr/bin/env ruby

require 'yaml'

$stdout.sync = true

HAPROXY_DIR = '/etc/haproxy/'
HAPROXY_YML = "#{HAPROXY_DIR}/haproxy.yml"
HAPROXY_CFG = "#{HAPROXY_DIR}/haproxy.cfg"

def render_haproxy_cfg(haproxy_yml = HAPROXY_YML, haproxy_cfg = HAPROXY_CFG, indent = 4)
    indent, output = ' ' * indent, ''

    config = YAML.safe_load File.read(haproxy_yml)

    config
        .reject {|section| %w[frontend backend].include? section}
        .each do |section, options|
            output << section << "\n"
            options.each {|option| output << indent << option << "\n"}
        end
    config
        .select {|section| %w[frontend backend].include? section}
        .each do |section, names|
            names.each do |name, options|
                output << "#{section} #{name}" << "\n"
                options.each {|option| output << indent << option << "\n"}
            end
        end

    File.write haproxy_cfg, output
end

def write_haproxy_cfg(config, haproxy_yml = HAPROXY_YML, haproxy_cfg = HAPROXY_CFG)
    File.write haproxy_yml, YAML.dump(config)
    render_haproxy_cfg haproxy_yml, haproxy_cfg
    puts File.read(haproxy_cfg)
end

if caller.empty?
    config = YAML.safe_load File.read(HAPROXY_YML)

    config['backend']['b1'] << 'server s1 http1.poc.svc:8000 check port 8000'
    write_haproxy_cfg config, HAPROXY_YML, HAPROXY_CFG
    system 'haproxy -f /etc/haproxy/haproxy.cfg -p /var/run/haproxy.pid -sf $(cat /var/run/haproxy.pid)'

    sleep 8

    config['backend']['b1'] << 'server s2 http2.poc.svc:8000 check port 8000'
    write_haproxy_cfg config, HAPROXY_YML, HAPROXY_CFG
    system 'haproxy -f /etc/haproxy/haproxy.cfg -p /var/run/haproxy.pid -sf $(cat /var/run/haproxy.pid)'

    sleep
end
