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
  vms = [ "07", "01", "86", "69" ]
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
  for_each = toset(local.vms)

  name        = each.key
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

data "opennebula_virtual_machines" "asd" {
  name_regex = ""
  sort_on    = "name"
  order      = "ASC"
  depends_on = [ opennebula_virtual_machine.asd ]
}

output "asd" {
  value = data.opennebula_virtual_machines.asd
}
