#!/usr/bin/env ruby
# vim:ts=4:sw=4:et:syn=ruby:
# rubocop:disable Lint/MissingCopEnableDirective
# rubocop:disable Layout/IndentationWidth
# rubocop:disable Style/Documentation
# frozen_string_literal: false

require 'base64'
require 'opennebula'
require 'rspec'

class ASD
    @@vm_states = OpenNebula::VirtualMachine::VM_STATE.map.with_index do
        |item, index|
        [item, index]
    end.to_h.freeze

    def initialize(xml_rpc_url, credentials)
        @client = OpenNebula::Client.new credentials, xml_rpc_url
    end

    def system_config
        system = OpenNebula::System.new(@client)

        rc = system.get_configuration
        raise rc.message if OpenNebula.is_error?(rc)

        pp rc.to_hash
    end

    def vm_monitoring
        vm_pool = OpenNebula::VirtualMachinePool.new(@client)

        rc = vm_pool.info(OpenNebula::Pool::INFO_ALL, -1, -1,
                          OpenNebula::VirtualMachinePool::INFO_ALL)
        raise rc.message if OpenNebula.is_error?(rc)

        vm_pool.monitoring(['CPU', 'MEMORY']).each do |vm_id, mon|
            pp vm_id
            pp mon['CPU'].last[1]
            pp mon['MEMORY'].last[1]
        end
    end

    def frontends
        zone_pool = OpenNebula::ZonePool.new(@client)

        rc = zone_pool.info
        raise rc.message if OpenNebula.is_error?(rc)

        pp zone_pool
    end

    def image_ds
        ds = OpenNebula::Datastore.new_with_id 1, @client

        rc = ds.info(true)
        raise rc.message if OpenNebula.is_error?(rc)

        pp ds.to_xml

    rescue StandardError => e
        STDERR.puts "asd"
        STDERR.puts e.full_message
    end

    def run
        #system_config
        #vm_monitoring
        #frontends
        image_ds
    end
end

if caller.empty?
    raise if ARGV.length < 2

    asd = ASD.new ARGV[0], ARGV[1]
    asd.run
end
