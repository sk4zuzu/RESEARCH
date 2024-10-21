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

locals {
  images = {
    vm = "https://marketplace.opennebula.io//appliance/0e7f57b0-9d02-013c-606f-7875a4a4f528/download/0"
  }
}

resource "opennebula_image" "asd" {
  for_each     = local.images
  name         = each.key
  datastore_id = "1"
  persistent   = false
  permissions  = "642"
  dev_prefix   = "vd"
  driver       = "qcow2"
  path         = each.value
}

resource "opennebula_virtual_machine" "asd" {
  name        = "vm"
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
  }

  nic {
    model      = "virtio"
    network_id = data.opennebula_virtual_network.service.id
  }

  os {
    arch = "x86_64"
    boot = ""
  }

  disk {
    image_id = opennebula_image.asd["vm"].id
    size     = 2048
  }

  graphics {
keymap = "en-us"
    listen = "0.0.0.0"
    type   = "VNC"
  }
}

data "opennebula_virtual_network_address_ranges" "service" {
  virtual_network_id = data.opennebula_virtual_network.service.id
}

output "service" {
  value = data.opennebula_virtual_network_address_ranges.service
}

resource "opennebula_virtual_network" "asd" {
  name = "asd"
  type = "bridge"
}

resource "opennebula_virtual_network_address_range" "asd" {
  for_each = {
    ar0 = {
      type     = "IP4"
      mac      = "02:01:92:01:68:00"
      size     = "5"
      ip4      = "192.168.0.100"
      hold_ips = []
    }
    ar1 = {
      type     = "IP4"
      mac      = "02:01:92:01:68:01"
      size     = "5"
      ip4      = "192.168.1.100"
      hold_ips = []
    }
    ar2 = {
      type     = "IP4"
      mac      = "02:01:92:01:68:02"
      size     = "5"
      ip4      = "192.168.2.100"
      hold_ips = []
    }
  }
  virtual_network_id = opennebula_virtual_network.asd.id
  ar_type            = each.value.type
  mac                = each.value.mac
  size               = each.value.size
  ip4                = each.value.ip4
  hold_ips           = each.value.hold_ips
}

data "opennebula_virtual_network_address_ranges" "asd" {
  virtual_network_id = opennebula_virtual_network.asd.id
}

output "asd" {
  value = data.opennebula_virtual_network_address_ranges.asd
}
