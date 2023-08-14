#!/usr/bin/env ruby

# frozen_string_literal: false

require 'logger'
require 'json'

LOG_PATH   = '/var/log/keepalived/failover.log'
FIFO_PATH  = ARGV[0] || '/run/keepalived/failover.sock'
STATE_PATH = '/run/keepalived/failover.state'

STATE_TO_DIRECTION = {
    'BACKUP'  => :down,
    'DELETED' => :down,
    'FAULT'   => :down,
    'MASTER'  => :up,
    'STOP'    => :down,
    nil       => :stay
}.freeze

$log       = Logger.new LOG_PATH
$log.level = Logger::DEBUG

def save_state(state, state_path = STATE_PATH)
    content = JSON.fast_generate({ state: state })
    File.open state_path, File::CREAT | File::TRUNC | File::WRONLY do |f|
        f.flock File::LOCK_EX
        f.write content
    end
end

def load_state(state_path = STATE_PATH)
    content = File.open state_path, File::RDONLY do |f|
        f.flock File::LOCK_EX
        f.read
    end
    JSON.parse content, symbolize_names: true
rescue Errno::ENOENT
    { state: 'UNKNOWN' }
end

def update_conf(conf_path, key, value)
    File.open conf_path, File::CREAT | File::RDWR, 0644 do |f|
        f.flock File::LOCK_EX
        content = f.read.lines.map(&:strip)
        if line = content.find { |line| line.match(/^[#\s]*#{key}\s*=/) }
            if value.nil?
                line.replace %[##{line}] unless line.start_with?(%[#])
            else
                line.replace %[#{key}="#{value}"]
            end
        else
            content << %[#{key}="#{value}"]
        end
        f.rewind
        f.puts content.join(%[\n])
        f.flush
        f.truncate f.pos
    end
end

def stay
    $log.debug :STAY
end

def up
    $log.debug :UP
    update_conf '/etc/conf.d/haproxy', 'rc_need', nil
    system 'rc-update -u; rc-service haproxy start'
end

def down
    $log.debug :DOWN
    update_conf '/etc/conf.d/haproxy', 'rc_need', 'THIS-SERVICE-IS-MASKED'
    system 'rc-update -u; rc-service haproxy stop'
end

def to_event(line)
    k = [:type, :name, :state, :priority]
    v = line.strip.split.map(&:strip).map{|s| s.delete_prefix('"').delete_suffix('"')}
    k.zip(v).to_h
end

def to_task(event)
    event[:state].upcase!

    state = load_state
    state[:state].upcase!

    if event[:type] != 'GROUP'
        direction = :stay
        ignored   = true
    else
        if STATE_TO_DIRECTION[event[:state]] == STATE_TO_DIRECTION[state[:state]]
            direction = :stay
            ignored   = false
        else
            direction = STATE_TO_DIRECTION[event[:state]]
            ignored   = false
        end
        save_state event[:state]
    end

    { event: event, from: state[:state], to: event[:state], direction: direction, ignored: ignored }
end

def process_events(fifo_path = FIFO_PATH)
    loop do
        begin
            File.open fifo_path, File::RDONLY do |f|
                f.each do |line|
                    event = to_event line
                    task = to_task event
                    $log.info task
                    method(task[:direction]).call
                end
            end
        rescue Errno::ENOENT
            next
        ensure
            sleep 1
        end
    end
end

def main
    process_events
end

main if caller.empty?
