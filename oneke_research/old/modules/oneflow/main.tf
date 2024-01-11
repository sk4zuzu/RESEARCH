terraform {
  required_providers {
    opennebula = {
      source  = "terraform.local/local/opennebula"
      version = "0.0.1"
    }
  }
}

variable "nics" {
  type = map(object({
    network_id = string
  }))
}

locals {
  images = {
    "vr_oneke" = "http://10.2.11.30/images/service_VRouter.qcow2"
    "cp_oneke" = "http://10.2.11.30/images/alpine317.qcow2"
  }
}

resource "opennebula_image" "oneke" {
  for_each     = local.images
  name         = each.key
  datastore_id = "1"
  persistent   = false
  permissions  = "642"
  dev_prefix   = "vd"
  driver       = "qcow2"
  path         = each.value
}

resource "opennebula_template" "vr_oneke" {
  name        = "vr_oneke"
  permissions = "642"
  cpu         = "0.5"
  vcpu        = "1"
  memory      = "512"

  context = {
    SET_HOSTNAME = "$NAME"
    NETWORK      = "YES"
    TOKEN        = "YES"
    REPORT_READY = "YES"

    SSH_PUBLIC_KEY = "$USER[SSH_PUBLIC_KEY]"
    PASSWORD       = "asd"

    ONEAPP_VNF_KEEPALIVED_PASSWORD = "asd"

    # ROUTER4

    ONEAPP_VNF_ROUTER4_ENABLED = "YES"

    # NAT4

    ONEAPP_VNF_NAT4_ENABLED        = "YES"
    ONEAPP_VNF_NAT4_INTERFACES_OUT = "eth0"

    # HAPROXY

    ONEAPP_VNF_HAPROXY_ENABLED         = "YES"
    ONEAPP_VNF_HAPROXY_ONEGATE_ENABLED = "YES"

    ONEAPP_VNF_HAPROXY_LB0_IP   = "<ETH0_IP0>"
    ONEAPP_VNF_HAPROXY_LB0_PORT = "5432"
  }

  os {
    arch = "x86_64"
    boot = ""
  }

  disk {
    image_id = opennebula_image.oneke["vr_oneke"].id
  }

  graphics {
    keymap = "en-us"
    listen = "0.0.0.0"
    type   = "VNC"
  }
}

locals {
  start_script = <<-SHELL
    #!/bin/sh
    set -e
    apk --no-cache add iproute2 jq nginx
    LOCAL_IP=$(ip -j a s dev eth0 | jq -r '.[0].addr_info | map(select(.family == "inet"))[0].local')
    echo "$LOCAL_IP" > /var/lib/nginx/html/index.html
    cat > /etc/nginx/http.d/default.conf <<'EOT'
    server {
      listen 2345 default_server;
      location / {
        root /var/lib/nginx/html/;
      }
    }
    EOT
    rc-update add nginx default
    # HAPROXY
    onegate vm update --data "ONEGATE_HAPROXY_LB0_IP=<ETH0_IP0>"
    onegate vm update --data "ONEGATE_HAPROXY_LB0_PORT=5432"
    onegate vm update --data "ONEGATE_HAPROXY_LB0_SERVER_HOST=$LOCAL_IP"
    onegate vm update --data "ONEGATE_HAPROXY_LB0_SERVER_PORT=2345"
  SHELL
}

resource "opennebula_template" "cp_oneke" {
  name        = "cp_oneke"
  permissions = "642"
  cpu         = "0.5"
  vcpu        = "1"
  memory      = "512"

  context = {
    SET_HOSTNAME = "$NAME"
    NETWORK      = "YES"
    TOKEN        = "YES"
    REPORT_READY = "YES"

    SSH_PUBLIC_KEY = "$USER[SSH_PUBLIC_KEY]"

    START_SCRIPT_BASE64 = base64encode(local.start_script)
  }

  os {
    arch = "x86_64"
    boot = ""
  }

  disk {
    image_id = opennebula_image.oneke["cp_oneke"].id
  }

  graphics {
    keymap = "en-us"
    listen = "0.0.0.0"
    type   = "VNC"
  }
}

locals {
  svc_yaml = <<-YAML
    name: svc_oneke
    deployment: straight
    roles:
      - name: vr_oneke
        cardinality: 1
        min_vms: 1
        cooldown: 5
        elasticity_policies: []
        scheduled_policies: []
        vm_template: ${opennebula_template.vr_oneke.id}
        vm_template_contents: |
          NIC = [
            NAME = "NIC0",
            NETWORK_ID = "${var.nics.eth0.network_id}" ]
          NIC = [
            NAME = "NIC1",
            NETWORK_ID = "${var.nics.eth1.network_id}" ]
      - name: cp_oneke
        parents: [vr_oneke]
        cardinality: 2
        min_vms: 1
        cooldown: 5
        elasticity_policies: []
        scheduled_policies: []
        vm_template: ${opennebula_template.cp_oneke.id}
        vm_template_contents: |
          NIC = [
            NAME = "NIC0",
            NETWORK_ID = "${var.nics.eth1.network_id}" ]
  YAML

  svc_template = yamldecode(local.svc_yaml)
}

resource "opennebula_service_template" "oneke" {
  name        = "svc_oneke"
  permissions = "642"
  template    = jsonencode({ "TEMPLATE" = { "BODY" = local.svc_template } })
}

resource "opennebula_service" "oneke" {
  name = "svc_oneke"

  template_id = opennebula_service_template.oneke.id

  timeouts {
    create = "15m"
    delete = "5m"
  }
}
