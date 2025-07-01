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
    vm = {
      path = "https://marketplace.opennebula.io//appliance/0e7f57b0-9d02-013c-606f-7875a4a4f528/download/0"
      type = null
      size = null
    }
    db = {
      path = null
      type = "DATABLOCK"
      size = 128
    }
  }
}

resource "opennebula_image" "asd" {
  for_each     = local.images
  name         = each.key
  datastore_id = "1"
  persistent   = false
  permissions  = "642"
  dev_prefix   = "vd"
  size         = each.value.size
  type         = each.value.type
  path         = each.value.path
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
  disk {
    image_id = opennebula_image.asd["db"].id
    size     = 256
  }

  graphics {
    keymap = "en-us"
    listen = "0.0.0.0"
    type   = "VNC"
  }
}
