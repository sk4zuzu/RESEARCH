terraform {
  required_providers {
    opennebula = {
      source  = "terraform.local/local/opennebula"
      version = "0.0.1"
    }
  }
}

variable "instances" {
  type = number
}

variable "nics" {
  type = map(object({
    network_id    = string
    floating_ip   = bool
    floating_only = bool
  }))
}

locals {
  images = { "vr_oneke" = "http://10.2.11.30/images/service_VRouter.qcow2" }
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

locals {
  start_script = <<-SHELL
    #!/bin/sh
    set -e
    ip link set dev eth0 up
  SHELL
}

resource "opennebula_virtual_router_instance_template" "oneke" {
  name        = "vr_oneke"
  permissions = "642"
  cpu         = "0.5"
  vcpu        = "1"
  memory      = "512"

  context = {
    SET_HOSTNAME = "$NAME"
    NETWORK      = "YES"
    TOKEN        = "YES"
    REPORT_READY = "NO"

    SSH_PUBLIC_KEY = "$USER[SSH_PUBLIC_KEY]"
    PASSWORD       = "asd"

    ONEAPP_VNF_KEEPALIVED_PASSWORD = "asd"

    # NAT4

    ONEAPP_VNF_NAT4_ENABLED        = "YES"
    ONEAPP_VNF_NAT4_INTERFACES_OUT = "eth0"

    # HAPROXY

    ONEAPP_VNF_HAPROXY_ENABLED         = "YES"
    ONEAPP_VNF_HAPROXY_ONEGATE_ENABLED = "YES"
    ONEAPP_VNF_HAPROXY_INTERFACES      = "!eth2"

    ONEAPP_VNF_HAPROXY_LB0_IP   = "<ONEAPP_VROUTER_ETH0_VIP0>"
    ONEAPP_VNF_HAPROXY_LB0_PORT = "5432"

    ONEAPP_VNF_HAPROXY_LB1_IP           = "<ONEAPP_VROUTER_ETH1_VIP0>"
    ONEAPP_VNF_HAPROXY_LB1_PORT         = "1234"
    ONEAPP_VNF_HAPROXY_LB1_SERVER0_HOST = "10.2.11.40"
    ONEAPP_VNF_HAPROXY_LB1_SERVER0_PORT = "9869"

    # LVS

    ONEAPP_VNF_LB_ENABLED         = "YES"
    ONEAPP_VNF_LB_ONEGATE_ENABLED = "YES"
    ONEAPP_VNF_LB_INTERFACES      = "!eth1"

    ONEAPP_VNF_LB0_IP        = "<ONEAPP_VROUTER_ETH0_VIP0>"
    ONEAPP_VNF_LB0_PORT      = "2345"
    ONEAPP_VNF_LB0_PROTOCOL  = "TCP"
    ONEAPP_VNF_LB0_METHOD    = "NAT"
    ONEAPP_VNF_LB0_SCHEDULER = "rr"

    ONEAPP_VNF_LB1_IP           = "<ONEAPP_VROUTER_ETH1_VIP0>"
    ONEAPP_VNF_LB1_PORT         = "4321"
    ONEAPP_VNF_LB1_PROTOCOL     = "TCP"
    ONEAPP_VNF_LB1_METHOD       = "NAT"
    ONEAPP_VNF_LB1_SCHEDULER    = "rr"
    ONEAPP_VNF_LB1_SERVER0_HOST = "10.2.11.40"
    ONEAPP_VNF_LB1_SERVER0_PORT = "9869"

    # SDNAT4

    ONEAPP_VNF_SDNAT4_ENABLED    = "YES"
    ONEAPP_VNF_SDNAT4_INTERFACES = "eth0 eth1"

    # DNS

    ONEAPP_VNF_DNS_ENABLED         = "YES"
    ONEAPP_VNF_DNS_INTERFACES      = "eth1"
    ONEAPP_VNF_DNS_MAX_CACHE_TTL   = ""
    ONEAPP_VNF_DNS_USE_ROOTSERVERS = "YES"

    # DHCP4

    ONEAPP_VNF_DHCP4_ENABLED    = "YES"
    ONEAPP_VNF_DHCP4_INTERFACES = "eth1"

    START_SCRIPT_BASE64 = base64encode(local.start_script)
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

resource "opennebula_virtual_router" "oneke" {
  name        = "vr_oneke"
  permissions = "642"

  instance_template_id = opennebula_virtual_router_instance_template.oneke.id
}

resource "opennebula_virtual_router_instance" "oneke" {
  count       = var.instances
  name        = "vr${count.index}.oneke"
  permissions = "642"
  memory      = "512"
  cpu         = "0.5"

  virtual_router_id = opennebula_virtual_router.oneke.id
}

resource "opennebula_virtual_router_nic" "eth0" {
  depends_on = [
    opennebula_virtual_router_instance.oneke,
  ]

  model         = "virtio"
  floating_ip   = var.nics.eth0.floating_ip
  floating_only = var.nics.eth0.floating_only

  virtual_router_id = opennebula_virtual_router.oneke.id
  network_id        = var.nics.eth0.network_id
}

resource "opennebula_virtual_router_nic" "eth1" {
  depends_on = [
    opennebula_virtual_router_instance.oneke,
    opennebula_virtual_router_nic.eth0,
  ]

  model         = "virtio"
  floating_ip   = var.nics.eth1.floating_ip
  floating_only = var.nics.eth1.floating_only

  virtual_router_id = opennebula_virtual_router.oneke.id
  network_id        = var.nics.eth1.network_id
}
