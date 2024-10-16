terraform {
  required_providers {
    opennebula = {
      source  = "terraform.local/local/opennebula"
      version = "0.0.1"
    }
  }
}

provider "opennebula" {
  endpoint      = "http://10.2.11.40:2633/RPC2"
  flow_endpoint = "http://10.2.11.40:2474"
  username      = "oneadmin"
  password      = "asd"
}

data "opennebula_virtual_network" "service" {
  name = "service"
}

data "opennebula_virtual_network" "private" {
  name = "private"
}

resource "opennebula_virtual_network" "reservation" {
  name              = "reservation"
  reservation_vnet  = data.opennebula_virtual_network.private.id
  reservation_ar_id = 0
  reservation_size  = 5
}

resource "opennebula_image" "router" {
  name         = "router"
  datastore_id = "1"
  persistent   = false
  permissions  = "642"
  dev_prefix   = "vd"
  driver       = "qcow2"
  path         = "https://marketplace.opennebula.io//appliance/cc96d537-f6c7-499f-83f1-15ac4058750e/download/0"
}

resource "opennebula_image" "backend" {
  name         = "backend"
  datastore_id = "1"
  persistent   = false
  permissions  = "642"
  dev_prefix   = "vd"
  driver       = "qcow2"
  path         = "https://marketplace.opennebula.io//appliance/d74a5f80-20bd-013d-0e49-7875a4a4f528/download/0"
}

resource "opennebula_template" "vnf" {
  name        = "vnf"
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

    # ROUTER4

    ONEAPP_VNF_ROUTER4_ENABLED = "YES"

    # NAT4

    ONEAPP_VNF_NAT4_ENABLED        = "YES"
    ONEAPP_VNF_NAT4_INTERFACES_OUT = "eth0"

    # DNS

    ONEAPP_VNF_DNS_ENABLED    = "YES"
    ONEAPP_VNF_DNS_INTERFACES = "eth1"

    # HAPROXY

    ONEAPP_VNF_HAPROXY_ENABLED         = "YES"
    ONEAPP_VNF_HAPROXY_ONEGATE_ENABLED = "YES"

    ONEAPP_VNF_HAPROXY_LB0_IP   = "<ETH0_EP0>"
    ONEAPP_VNF_HAPROXY_LB0_PORT = "5432"
  }

  os {
    arch = "x86_64"
    boot = ""
  }

  disk {
    image_id = opennebula_image.router.id
  }

  graphics {
    keymap = "en-us"
    listen = "0.0.0.0"
    type   = "VNC"
  }
}

resource "opennebula_template" "backend" {
  name        = "backend"
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
    PASSWORD       = "asd"

    START_SCRIPT_BASE64 = base64encode(
      <<-SHELL
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
          onegate vm update --data "ONEGATE_HAPROXY_LB0_IP=<ETH0_EP0>"
          onegate vm update --data "ONEGATE_HAPROXY_LB0_PORT=5432"
          onegate vm update --data "ONEGATE_HAPROXY_LB0_SERVER_HOST=$LOCAL_IP"
          onegate vm update --data "ONEGATE_HAPROXY_LB0_SERVER_PORT=2345"
      SHELL
    )
  }

  os {
    arch = "x86_64"
    boot = ""
  }

  disk {
    image_id = opennebula_image.backend.id
  }

  graphics {
    keymap = "en-us"
    listen = "0.0.0.0"
    type   = "VNC"
  }
}

resource "opennebula_service_template" "service" {
  name        = "service"
  permissions = "642"

  template = jsonencode({
    TEMPLATE = {
      BODY = {
        name       = "service"
        deployment = "straight"
        roles = [
          {
            name                 = "vnf"
            cardinality          = 1
            min_vms              = 1
            cooldown             = 5
            elasticity_policies  = []
            scheduled_policies   = []
            vm_template          = tonumber(opennebula_template.vnf.id)
            vm_template_contents = <<-TEMPLATE
              NIC = [
                NAME       = "_NIC0",
                NETWORK_ID = "$service" ]
              NIC = [
                NAME       = "_NIC1",
                NETWORK_ID = "$private" ]
            TEMPLATE
          },
          {
            name                 = "backend"
            parents              = ["vnf"]
            cardinality          = 2
            min_vms              = 1
            cooldown             = 5
            elasticity_policies  = []
            scheduled_policies   = []
            vm_template          = tonumber(opennebula_template.backend.id)
            vm_template_contents = <<-TEMPLATE
              NIC = [
                NAME       = "_NIC0",
                DNS        = "$${vnf.TEMPLATE.CONTEXT.ETH1_IP}",
                GATEWAY    = "$${vnf.TEMPLATE.CONTEXT.ETH1_IP}",
                NETWORK_ID = "$private" ]
            TEMPLATE
          },
        ]
        networks = {
          service = "M|network|service||id:"
          private = "M|network|private||id:"
        }
      }
    }
  })
}

resource "opennebula_service" "service" {
  name = "service"

  template_id = opennebula_service_template.service.id

  extra_template = jsonencode({
      networks_values = [
        { service = { id = tostring(data.opennebula_virtual_network.service.id) } },
        { private = { id = tostring(opennebula_virtual_network.reservation.id) } },
      ]
      roles = [
        { cardinality = 2 },
        { cardinality = 1 },
      ]
  })

  timeouts {
    create = "15m"
    delete = "5m"
  }
}
