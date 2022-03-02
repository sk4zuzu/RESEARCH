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
        SOURCE="/svc/img/service_kubernetes_ubuntu-6.2.0-1.20220302.qcow2"
        SIZE="5120"
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

    def ensure_template(name)
        return unless find_template(name).nil?

        template = OpenNebula::Template.new OpenNebula::Template.build_xml, @client

        image = find_image name
        raise if image.nil?

        contents = <<~CONTENTS
        NAME="#{name}"
        CONTEXT=[
          NETWORK="YES",
          ONEAPP_K8S_ADDRESS="$ONEAPP_K8S_ADDRESS",
          ONEAPP_K8S_ADMIN_USERNAME="$ONEAPP_K8S_ADMIN_USERNAME",
          ONEAPP_K8S_HASH="$ONEAPP_K8S_HASH",
          ONEAPP_K8S_LOADBALANCER_CONFIG="$ONEAPP_K8S_LOADBALANCER_CONFIG",
          ONEAPP_K8S_LOADBALANCER_RANGE="$ONEAPP_K8S_LOADBALANCER_RANGE",
          ONEAPP_K8S_NODENAME="$ONEAPP_K8S_NODENAME",
          ONEAPP_K8S_PODS_NETWORK="$ONEAPP_K8S_PODS_NETWORK",
          ONEAPP_K8S_PORT="$ONEAPP_K8S_PORT",
          ONEAPP_K8S_TAINTED_MASTER="$ONEAPP_K8S_TAINTED_MASTER",
          ONEAPP_K8S_TOKEN="$ONEAPP_K8S_TOKEN",
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
          ORIGINAL_SIZE="5120",
          READONLY="NO",
          SAVE="NO",
          SIZE="5120",
          TM_MAD="ssh",
          TYPE="FILE" ]
        GRAPHICS=[
          LISTEN="0.0.0.0",
          TYPE="vnc" ]
        INPUTS_ORDER="ONEAPP_K8S_ADDRESS,ONEAPP_K8S_TOKEN,ONEAPP_K8S_HASH,ONEAPP_K8S_NODENAME,ONEAPP_K8S_PORT,ONEAPP_K8S_TAINTED_MASTER,ONEAPP_K8S_PODS_NETWORK,ONEAPP_K8S_ADMIN_USERNAME,ONEAPP_K8S_LOADBALANCER_RANGE,ONEAPP_K8S_LOADBALANCER_CONFIG"
        MEMORY="3072"
        OS=[
          ARCH="x86_64" ]
        USER_INPUTS=[
          ONEAPP_K8S_ADDRESS="O|text|Master node address",
          ONEAPP_K8S_ADMIN_USERNAME="O|text|UI dashboard admin account (default admin-user)",
          ONEAPP_K8S_HASH="O|text|Secret hash (to join node into the cluster)",
          ONEAPP_K8S_LOADBALANCER_CONFIG="O|text64|Custom LoadBalancer config",
          ONEAPP_K8S_LOADBALANCER_RANGE="O|text|LoadBalancer IP range (default none)",
          ONEAPP_K8S_NODENAME="O|text|Master node name",
          ONEAPP_K8S_PODS_NETWORK="O|text|Pods network in CIDR (default 10.244.0.0/16)",
          ONEAPP_K8S_PORT="O|text|Kubernetes API port (default 6443)",
          ONEAPP_K8S_TAINTED_MASTER="O|boolean|Master node acts as control-plane only (default no)",
          ONEAPP_K8S_TOKEN="O|password|Secret token (to join node into the cluster)" ]
        VCPU="2"
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

    def ensure_service_template(name, vm_template_id)
        return unless find_service_template(name).nil?

        template = {
          "name": "k8s",
          "deployment": "straight",
          "description": "",
          "roles": [
            {
              "name": "master",
              "cardinality": 1,
              "vm_template_contents": "REPORT_READY=\"YES\"\nTOKEN=\"YES\"\nNIC=[NAME=\"NIC0\",NETWORK_ID=\"$Public\"]\n",
              "vm_template": vm_template_id.to_s,
              "elasticity_policies": [],
              "scheduled_policies": [],
            },
            {
              "name": "worker",
              "cardinality": 1,
              "vm_template_contents": "REPORT_READY=\"YES\"\nTOKEN=\"YES\"\nNIC=[NAME=\"NIC0\",NETWORK_ID=\"$Public\"]\n",
              "vm_template": vm_template_id.to_s,
              "parents": [
                "master",
              ],
              "elasticity_policies": [],
              "scheduled_policies": [],
            },
            {
              "name": "storage",
              "cardinality": 1,
              "vm_template_contents": "REPORT_READY=\"YES\"\nTOKEN=\"YES\"\nNIC=[NAME=\"NIC0\",NETWORK_ID=\"$Public\"]\n",
              "vm_template": vm_template_id.to_s,
              "parents": [
                "master",
              ],
              "elasticity_policies": [],
              "scheduled_policies": [],
            },
          ],
          "networks": {
            "Public": "M|network|Public| |id:",
          },
          "ready_status_gate": true,
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

    one = One.new xml_rpc_url, ARGV[1]
    one.ensure_image 'k8s'
    one.ensure_template 'k8s'

    template = one.find_template 'k8s'
    raise if template.nil?

    svc = Svc.new oneflow_url, ARGV[1]
    svc.ensure_service_template 'k8s', template.id
end
