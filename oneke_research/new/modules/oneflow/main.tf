terraform {
  required_providers {
    opennebula = {
      source  = "terraform.local/local/opennebula"
      version = "0.0.1"
    }
  }
}

variable "network_id" {
  type = string
}

locals {
  images       = { "cp_oneke" = "http://10.2.11.30/images/alpine317.qcow2" }
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
    onegate vm update --data "ONEGATE_HAPROXY_LB0_IP=<ONEAPP_VROUTER_ETH0_VIP0>"
    onegate vm update --data "ONEGATE_HAPROXY_LB0_PORT=5432"
    onegate vm update --data "ONEGATE_HAPROXY_LB0_SERVER_HOST=$LOCAL_IP"
    onegate vm update --data "ONEGATE_HAPROXY_LB0_SERVER_PORT=2345"
    # LVS
    onegate vm update --data "ONEGATE_LB0_IP=<ONEAPP_VROUTER_ETH0_VIP0>"
    onegate vm update --data "ONEGATE_LB0_PORT=2345"
    onegate vm update --data "ONEGATE_LB0_SERVER_HOST=$LOCAL_IP"
    onegate vm update --data "ONEGATE_LB0_SERVER_PORT=2345"
  SHELL
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

resource "opennebula_template" "oneke" {
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
    BACKEND      = "YES"

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
      - name: cp_oneke
        cardinality: 2
        min_vms: 1
        cooldown: 5
        elasticity_policies: []
        scheduled_policies: []
        vm_template: ${opennebula_template.oneke.id}
        vm_template_contents: |
          NIC = [
            NAME = "NIC0",
            NETWORK_ID = "${var.network_id}" ]
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
