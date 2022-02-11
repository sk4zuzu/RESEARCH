#!/usr/bin/env ruby
# vim:ts=4:sw=4:et:syn=ruby:
# rubocop:disable Lint/MissingCopEnableDirective
# rubocop:disable Layout/HeredocIndentation
# rubocop:disable Layout/IndentationWidth
# rubocop:disable Style/Documentation
# frozen_string_literal: false

require 'base64'
require 'opennebula'
require 'rspec'

class ASD
    def initialize(xml_rpc_url, credentials)
        @client = OpenNebula::Client.new credentials, xml_rpc_url
    end

    def find_image(name)
        image_pool = OpenNebula::ImagePool.new @client, -1

        err = image_pool.info
        if OpenNebula.is_error? err
            p err; raise
        end

        image_pool.find { |image| image.name == name }
    end

    def ensure_datablock(name)
        return unless find_image(name).nil?

        image = OpenNebula::Image.new OpenNebula::Image.build_xml, @client

        err = image.allocate <<~CONTENTS, 1
        NAME="#{name}"
        TYPE="DATABLOCK"
        PERSISTENT="YES"
        FORMAT="qcow2"
        FS="ext4"
        SIZE="36864"
        DEV_PREFIX="vd"
        CONTENTS

        if OpenNebula.is_error? err
            p err; raise
        end
    end

    def find_template(name)
        template_pool = OpenNebula::TemplatePool.new @client, -1

        err = template_pool.info
        if OpenNebula.is_error? err
            p err; raise
        end

        template_pool.find { |template| template.name == name }
    end

    def ensure_template(name, role = :agent)
        return unless find_template(name).nil?

        template = OpenNebula::Template.new OpenNebula::Template.build_xml, @client

        contents = <<~CONTENTS
        NAME="#{name}"
        CPU="1"
        DISK=[
          ALLOW_ORPHANS="YES",
          CLONE="YES",
          CLONE_TARGET="SYSTEM",
          CLUSTER_ID="0",
          DATASTORE="default",
          DATASTORE_ID="1",
          DEV_PREFIX="vd",
          DISK_ID="0",
          DISK_SNAPSHOT_TOTAL_SIZE="0",
          DISK_TYPE="FILE",
          DRIVER="qcow2",
          FORMAT="qcow2",
          IMAGE="alpine314",
          IMAGE_ID="0",
          IMAGE_STATE="1",
          LN_TARGET="SYSTEM",
          ORIGINAL_SIZE="256",
          READONLY="NO",
          SAVE="NO",
          SIZE="8192",
          TM_MAD="ssh",
          TYPE="FILE" ]
        GRAPHICS=[
          LISTEN="0.0.0.0",
          TYPE="vnc" ]
        LOGO="images/logos/linux.png"
        LXD_SECURITY_PRIVILEGED="true"
        NIC=[
          NETWORK_ID="0",
          SECURITY_GROUPS="0" ]
        NIC_DEFAULT=[
          MODEL="virtio" ]
        OS=[
          ARCH="x86_64" ]
        CONTENTS

        case role
        when :server
            start = Base64.encode64 <<~SCRIPT
            #!/usr/bin/env sh
            set -e
            hostname #{name}
            mount --make-shared /
            mount -t cgroup cgroup /sys/fs/cgroup/
            apk --no-cache add haproxy nfs-utils open-iscsi
            rc-update add haproxy
            rc-update add iscsid
            SCRIPT

            contents << <<~CONTENTS
            CONTEXT=[
              NETWORK="YES",
              SSH_PUBLIC_KEY="$USER[SSH_PUBLIC_KEY]",
              START_SCRIPT_BASE64="#{start}" ]
            MEMORY="2048"
            CONTENTS
        when :agent
            image = find_image name
            raise if image.nil?

            start = Base64.encode64 <<~SCRIPT
            #!/usr/bin/env sh
            set -e
            hostname #{name}
            mount --make-shared /
            mount -t cgroup cgroup /sys/fs/cgroup/
            install -o 0 -g 0 -m u=rwx,go=rx -d /var/lib/longhorn/
            mount /dev/vdb /var/lib/longhorn/
            apk --no-cache add haproxy nfs-utils open-iscsi
            rc-update add haproxy
            rc-update add iscsid
            SCRIPT

            contents << <<~CONTENTS
            CONTEXT=[
              NETWORK="YES",
              SSH_PUBLIC_KEY="$USER[SSH_PUBLIC_KEY]",
              START_SCRIPT_BASE64="#{start}" ]
            DISK=[
              ALLOW_ORPHANS="YES",
              CLONE="NO",
              CLUSTER_ID="0",
              DATASTORE="default",
              DATASTORE_ID="1",
              DEV_PREFIX="vd",
              DISK_ID="1",
              DISK_SNAPSHOT_TOTAL_SIZE="0",
              DISK_TYPE="FILE",
              DRIVER="qcow2",
              FORMAT="qcow2",
              IMAGE="asd3",
              IMAGE_ID="#{image.id}",
              IMAGE_STATE="1",
              LN_TARGET="SYSTEM",
              READONLY="NO",
              SAVE="NO",
              TM_MAD="ssh",
              TYPE="FILE" ]
            MEMORY="3072"
            CONTENTS
        end

        err = template.allocate contents

        if OpenNebula.is_error? err
            p err; raise
        end
    end

    def find_vm(name)
        vm_pool = OpenNebula::VirtualMachinePool.new @client, -1

        err = vm_pool.info
        if OpenNebula.is_error? err
            p err; raise
        end

        vm_pool.find { |vm| vm.name == name }
    end

    def ensure_vm(name)
        return unless find_vm(name).nil?

        template = find_template name
        raise if template.nil?

        err = template.instantiate name
        if OpenNebula.is_error? err
            p err; raise
        end
    end
end

if caller.empty?
    raise if ARGV.length < 2

    asd = ASD.new ARGV[0], ARGV[1]

    %w[asd0].each do |name|
        asd.ensure_template name, :server
        asd.ensure_vm name
    end

    %w[asd1 asd2 asd3].each do |name|
        asd.ensure_datablock name
        asd.ensure_template name, :agent
        asd.ensure_vm name
    end
end
