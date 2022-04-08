#!/usr/bin/env ruby
# vim:ts=4:sw=4:et:syn=ruby:
# rubocop:disable Lint/MissingCopEnableDirective
# rubocop:disable Layout/HeredocIndentation
# rubocop:disable Layout/IndentationWidth
# rubocop:disable Style/Documentation
# frozen_string_literal: false

require 'base64'
require 'faraday'
require 'json'
require 'opennebula'
require 'rspec'

DATASTORE    = 'default'
DATASTORE_ID = '1'

class One
    def initialize(xml_rpc_url, credentials)
        @client = OpenNebula::Client.new credentials, xml_rpc_url
        @image_source = File.expand_path '~/_git/one-infra/tools/building_images/build/export/'
        @image_prefix = nil
    end

    def find_latest_qcow2
        File.basename Dir["#{@image_source}/#{@image_prefix}*.qcow2"].max
    end

    def find_image(name)
        image_pool = OpenNebula::ImagePool.new @client, -1

        error = image_pool.info
        raise error if OpenNebula.is_error? error

        image_pool.find { |image| image.name == name }
    end

    def ensure_image(name)
        return unless find_image(name).nil?

        image = OpenNebula::Image.new OpenNebula::Image.build_xml, @client

        contents = <<~CONTENTS
        NAME="#{name}"
        TYPE="OS"
        PERSISTENT="NO"
        FORMAT="qcow2"
        DEV_PREFIX="vd"
        SOURCE="/var/lib/one/datastores/img/#{find_latest_qcow2}"
        SIZE="20480"
        CONTENTS

        error = image.allocate contents, DATASTORE_ID.to_i
        raise error if OpenNebula.is_error? error
    end

    def find_template(name)
        template_pool = OpenNebula::TemplatePool.new @client, -1

        error = template_pool.info
        raise error if OpenNebula.is_error? error

        template_pool.find { |template| template.name == name }
    end
end

class Vnf < One
    def initialize(xml_rpc_url, credentials)
        super xml_rpc_url, credentials
        @image_prefix = 'service_vnf-'
    end

    def ensure_template(name)
        return unless find_template(name).nil?

        template = OpenNebula::Template.new OpenNebula::Template.build_xml, @client

        image = find_image name
        raise if image.nil?

        contents = <<~CONTENTS
        NAME="#{name}"
        CONTEXT = [
          NETWORK = "YES",
          ONEAPP_VNF_DHCP4_ENABLED = "$ONEAPP_VNF_DHCP4_ENABLED",
          ONEAPP_VNF_DHCP4_INTERFACES = "$ONEAPP_VNF_DHCP4_INTERFACES",
          ONEAPP_VNF_DHCP4_LEASE_TIME = "$ONEAPP_VNF_DHCP4_LEASE_TIME",
          ONEAPP_VNF_DNS_ENABLED = "$ONEAPP_VNF_DNS_ENABLED",
          ONEAPP_VNF_DNS_INTERFACES = "$ONEAPP_VNF_DNS_INTERFACES",
          ONEAPP_VNF_DNS_MAX_CACHE_TTL = "$ONEAPP_VNF_DNS_MAX_CACHE_TTL",
          ONEAPP_VNF_DNS_USE_ROOTSERVERS = "$ONEAPP_VNF_DNS_USE_ROOTSERVERS",
          ONEAPP_VNF_KEEPALIVED_ENABLED = "$ONEAPP_VNF_KEEPALIVED_ENABLED",
          ONEAPP_VNF_KEEPALIVED_VRID = "$ONEAPP_VNF_KEEPALIVED_VRID",
          ONEAPP_VNF_LB0_IP = "$ONEAPP_VNF_LB0_IP",
          ONEAPP_VNF_LB0_PORT = "$ONEAPP_VNF_LB0_PORT",
          ONEAPP_VNF_LB0_METHOD = "$ONEAPP_VNF_LB0_METHOD",
          ONEAPP_VNF_LB0_PROTOCOL = "$ONEAPP_VNF_LB0_PROTOCOL",
          ONEAPP_VNF_LB0_SCHEDULER = "$ONEAPP_VNF_LB0_SCHEDULER",
          ONEAPP_VNF_LB_ENABLED = "$ONEAPP_VNF_LB_ENABLED",
          ONEAPP_VNF_LB_ONEGATE_ENABLED = "yes",
          ONEAPP_VNF_LB_REFRESH_RATE = "$ONEAPP_VNF_LB_REFRESH_RATE",
          ONEAPP_VNF_NAT4_ENABLED = "$ONEAPP_VNF_NAT4_ENABLED",
          ONEAPP_VNF_NAT4_INTERFACES_OUT = "$ONEAPP_VNF_NAT4_INTERFACES_OUT",
          ONEAPP_VNF_ROUTER4_ENABLED = "$ONEAPP_VNF_ROUTER4_ENABLED",
          ONEAPP_VNF_ROUTER4_INTERFACES = "$ONEAPP_VNF_ROUTER4_INTERFACES",
          ONEAPP_VROUTER_ETH0_VIP0 = "$ONEAPP_VROUTER_ETH0_VIP0",
          PASSWORD = "7OXSPBB+c+MhdUnrPvoOZg==",
          REPORT_READY = "YES",
          SSH_PUBLIC_KEY="$USER[SSH_PUBLIC_KEY]",
          START_SCRIPT_BASE64 = "cHJpbnRlbnYgfCBzb3J0ID4gL3ByaW50ZW52LnR4dA==",
          TOKEN = "YES" ]
        CPU = "1"
        DISK = [
          DATASTORE="#{DATASTORE}",
          DATASTORE_ID="#{DATASTORE_ID}",
          IMAGE="#{name}",
          IMAGE_ID="#{image.id}" ]
        GRAPHICS = [
          LISTEN = "0.0.0.0",
          TYPE = "VNC" ]
        HOT_RESIZE = [
          CPU_HOT_ADD_ENABLED = "NO",
          MEMORY_HOT_ADD_ENABLED = "NO" ]
        INFO = "Please do not use this VM Template for vCenter VMs. Refer to the documentation https://bit.ly/37NcJ0Y"
        INPUTS_ORDER = "ONEAPP_VNF_DHCP4_ENABLED,ONEAPP_VNF_DHCP4_INTERFACES,ONEAPP_VNF_DNS_ENABLED,ONEAPP_VNF_DNS_INTERFACES,ONEAPP_VNF_NAT4_ENABLED,ONEAPP_VNF_NAT4_INTERFACES_OUT,ONEAPP_VNF_ROUTER4_ENABLED,ONEAPP_VNF_ROUTER4_INTERFACES,ONEAPP_VNF_DHCP4_LEASE_TIME,ONEAPP_VNF_DNS_MAX_CACHE_TTL,ONEAPP_VNF_DNS_USE_ROOTSERVERS,ONEAPP_VNF_LB_ENABLED,ONEAPP_VNF_LB_REFRESH_RATE,ONEAPP_VNF_LB0_IP,ONEAPP_VNF_LB0_PROTOCOL,ONEAPP_VNF_LB0_PORT,ONEAPP_VNF_LB0_METHOD,ONEAPP_VNF_LB0_SCHEDULER,ONEAPP_VROUTER_ETH0_VIP0,ONEAPP_VNF_KEEPALIVED_ENABLED,ONEAPP_VNF_KEEPALIVED_VRID"
        LXD_SECURITY_PRIVILEGED = "true"
        MEMORY = "512"
        MEMORY_UNIT_COST = "MB"
        NIC = [
          NETWORK = "private",
          SECURITY_GROUPS = "0" ]
        NIC_DEFAULT = [
          MODEL = "virtio" ]
        OS = [
          ARCH = "x86_64",
          FIRMWARE = "",
          FIRMWARE_SECURE = "YES" ]
        USER_INPUTS = [
          ONEAPP_VNF_DHCP4_ENABLED = "O|boolean|Enable DHCPv4| |",
          ONEAPP_VNF_DHCP4_INTERFACES = "O|text|DHCP4 - Listening Interfaces| |",
          ONEAPP_VNF_DHCP4_LEASE_TIME = "O|number|*** DHCP4 - Lease Time [sec]| |3600",
          ONEAPP_VNF_DNS_ENABLED = "O|boolean|Enable DNS Server| |",
          ONEAPP_VNF_DNS_INTERFACES = "O|text|DNS - Listening Interfaces| |",
          ONEAPP_VNF_DNS_MAX_CACHE_TTL = "O|number|*** DNS - Maximum Caching Time [sec]| |3600",
          ONEAPP_VNF_DNS_USE_ROOTSERVERS = "O|boolean|*** DNS - Use Rootservers| |YES",
          ONEAPP_VNF_KEEPALIVED_ENABLED = "O|boolean|ONEAPP_VNF_KEEPALIVED_ENABLED| |YES",
          ONEAPP_VNF_KEEPALIVED_VRID = "O|text|ONEAPP_VNF_KEEPALIVED_VRID| |",
          ONEAPP_VNF_LB0_IP = "O|text|ONEAPP_VNF_LB0_IP| |",
          ONEAPP_VNF_LB0_PORT = "O|number|ONEAPP_VNF_LB0_PORT| |6443",
          ONEAPP_VNF_LB0_METHOD = "O|text|ONEAPP_VNF_LB0_METHOD| |dr",
          ONEAPP_VNF_LB0_PROTOCOL = "O|text|ONEAPP_VNF_LB0_PROTOCOL| |tcp",
          ONEAPP_VNF_LB0_SCHEDULER = "O|text|ONEAPP_VNF_LB0_SCHEDULER| |",
          ONEAPP_VNF_LB_ENABLED = "O|boolean|ONEAPP_VNF_LB_ENABLED| |YES",
          ONEAPP_VNF_LB_REFRESH_RATE = "O|number|ONEAPP_VNF_LB_REFRESH_RATE| |",
          ONEAPP_VNF_NAT4_ENABLED = "O|boolean|Enable NAT| |",
          ONEAPP_VNF_NAT4_INTERFACES_OUT = "O|text|NAT - Outgoing Interfaces| |",
          ONEAPP_VNF_ROUTER4_ENABLED = "O|boolean|Enable Router| |",
          ONEAPP_VNF_ROUTER4_INTERFACES = "O|text|Router - Interfaces| |",
          ONEAPP_VROUTER_ETH0_VIP0 = "O|text|ONEAPP_VROUTER_ETH0_VIP0| |" ]
        SCHED_REQUIREMENTS = "HYPERVISOR!=\\\"vcenter\\\""
        CONTENTS

        error = template.allocate contents
        raise error if OpenNebula.is_error? error
    end
end

class K8s < One
    def initialize(xml_rpc_url, credentials)
        super xml_rpc_url, credentials
        @image_prefix = 'service_kubernetes_ubuntu-'
    end

    def ensure_template(name)
        return unless find_template(name).nil?

        template = OpenNebula::Template.new OpenNebula::Template.build_xml, @client

        image = find_image name
        raise if image.nil?

        contents = <<~CONTENTS
        NAME="#{name}"
        CONTEXT=[
          NETWORK="YES",
          ONEAPP_K8S_LOADBALANCER_CONFIG="$ONEAPP_K8S_LOADBALANCER_CONFIG",
          ONEAPP_K8S_LOADBALANCER_RANGE="$ONEAPP_K8S_LOADBALANCER_RANGE",
          ONEAPP_K8S_PODS_NETWORK="$ONEAPP_K8S_PODS_NETWORK",
          ONEAPP_K8S_PORT="$ONEAPP_K8S_PORT",
          SSH_PUBLIC_KEY="$USER[SSH_PUBLIC_KEY]",
          REPORT_READY="YES",
          TOKEN="YES" ]
        CPU="2"
        DISK=[
          ALLOW_ORPHANS="YES",
          CLONE="YES",
          CLONE_TARGET="SYSTEM",
          CLUSTER_ID="0",
          DATASTORE="#{DATASTORE}",
          DATASTORE_ID="#{DATASTORE_ID}",
          DEV_PREFIX="vd",
          DISK_ID="0",
          DISK_SNAPSHOT_TOTAL_SIZE="0",
          DISK_TYPE="FILE",
          DRIVER="qcow2",
          FORMAT="qcow2",
          IMAGE="#{name}",
          IMAGE_ID="#{image.id}",
          LN_TARGET="SYSTEM",
          ORIGINAL_SIZE="20480",
          READONLY="NO",
          SAVE="NO",
          SIZE="20480",
          TM_MAD="ssh",
          TYPE="FILE" ]
        GRAPHICS=[
          LISTEN="0.0.0.0",
          TYPE="vnc" ]
        INPUTS_ORDER="ONEAPP_K8S_PORT,ONEAPP_K8S_PODS_NETWORK,ONEAPP_K8S_LOADBALANCER_RANGE,ONEAPP_K8S_LOADBALANCER_CONFIG"
        MEMORY="2048"
        OS=[
          ARCH="x86_64" ]
        USER_INPUTS=[
          ONEAPP_K8S_LOADBALANCER_CONFIG="O|text64|Custom LoadBalancer config",
          ONEAPP_K8S_LOADBALANCER_RANGE="O|text|LoadBalancer IP range (default none)",
          ONEAPP_K8S_PODS_NETWORK="O|text|Pods network in CIDR (default 10.244.0.0/16)| |10.244.0.0/16",
          ONEAPP_K8S_PORT="O|text|Kubernetes API port (default 6443)| |6443" ]
        VCPU="2"
        SCHED_REQUIREMENTS = "HYPERVISOR!=\\\"vcenter\\\""
        NIC = [
          NETWORK = "private",
          SECURITY_GROUPS = "0" ]
        NIC_DEFAULT = [
          MODEL = "virtio" ]
        CONTENTS

        error = template.allocate contents
        raise error if OpenNebula.is_error? error
    end
end

class Svc
    def initialize(oneflow_url, credentials)
        @client = Faraday.new oneflow_url
        @client.request :basic_auth, *credentials.split(':')
    end

    def find_service_template(name)
        response = @client.get "/service_template"
        unless response.status == 200
            pp response, STDERR
            return nil
        end

        body      = JSON.parse response.body
        documents = body.dig('DOCUMENT_POOL', 'DOCUMENT')

        return nil if documents.nil?

        documents.find { |document| document['NAME'] == name }
    end

    def ensure_service_template(name, vm_template_ids)
        return unless find_service_template(name).nil?

        template = {
          "name": "k8s",
          "deployment": "straight",
          "description": "",
          "roles": [
            {
              "name": "vnf",
              "cardinality": 1,
              "vm_template_contents": "NIC=[NAME=\"_NIC0\",NETWORK_ID=\"$Private\"]\n",
              "vm_template": vm_template_ids[:vnf].to_s,
              "elasticity_policies": [],
              "scheduled_policies": []
            },
            {
              "name": "master",
              "cardinality": 1,
              "vm_template_contents": "NIC=[NAME=\"_NIC0\",NETWORK_ID=\"$Private\"]\n",
              "vm_template": vm_template_ids[:k8s].to_s,
              "parents": ["vnf"],
              "elasticity_policies": [],
              "scheduled_policies": []
            },
            {
              "name": "worker",
              "cardinality": 0,
              "vm_template_contents": "NIC=[NAME=\"_NIC0\",NETWORK_ID=\"$Private\"]\n",
              "vm_template": vm_template_ids[:k8s].to_s,
              "parents": ["master"],
              "elasticity_policies": [],
              "scheduled_policies": []
            },
            {
              "name": "storage",
              "cardinality": 0,
              "vm_template_contents": "NIC=[NAME=\"_NIC0\",NETWORK_ID=\"$Private\"]\n",
              "vm_template": vm_template_ids[:k8s].to_s,
              "parents": ["master"],
              "elasticity_policies": [],
              "scheduled_policies": []
            }
          ],
          "networks": {
            #"Public": "M|network|Public| |id:",
            "Private": "M|network|Private| |id:"
          },
          "ready_status_gate": true
        }

        response = @client.post "/service_template" do |request|
            request.body = template.to_json
        end
        unless response.status == 201
            pp response, STDERR
            return nil
        end

        JSON.parse response.body
    end
end

if caller.empty?
    raise if ARGV.length < 2

    xml_rpc_url = "http://#{ARGV[0]}:2633/RPC2"
    oneflow_url = "http://#{ARGV[0]}:2474"

    vnf = Vnf.new xml_rpc_url, ARGV[1]
    vnf.ensure_image 'vnf'
    vnf.ensure_template 'vnf'
    vnf_template = vnf.find_template 'vnf'
    raise if vnf_template.nil?

    k8s = K8s.new xml_rpc_url, ARGV[1]
    k8s.ensure_image 'k8s'
    k8s.ensure_template 'k8s'
    k8s_template = k8s.find_template 'k8s'
    raise if k8s_template.nil?

    svc = Svc.new oneflow_url, ARGV[1]
    svc.ensure_service_template 'k8s', {
        vnf: vnf_template.id,
        k8s: k8s_template.id
    }
end
