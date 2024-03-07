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

locals {
  distros = {
    floating_alpine318 = {
      image_path = "http://10.2.11.30/images/export/alpine318.qcow2"
    }
  }
  instances = {
    floating0 = {
      image_id = opennebula_image.images["floating_alpine318"].id
    }
    floating1 = {
      image_id = opennebula_image.images["floating_alpine318"].id
    }
  }
}

data "opennebula_virtual_network" "service" {
  name = "service"
}

resource "opennebula_image" "images" {
  for_each     = local.distros
  name         = each.key
  datastore_id = "1"
  persistent   = false
  permissions  = "642"
  dev_prefix   = "vd"
  driver       = "qcow2"
  path         = each.value.image_path
}

resource "opennebula_virtual_machine" "machines" {
  for_each = local.instances

  name        = each.key
  permissions = "642"
  memory      = "1024"

  cpumodel {
    model = "host-passthrough"
  }
  cpu  = "0.5"
  vcpu = "1"

  os {
    arch = "x86_64"
    boot = ""
  }

  context = {
    SET_HOSTNAME = "$NAME"
    NETWORK      = "YES"
    TOKEN        = "NO"
    REPORT_READY = "NO"

    SSH_PUBLIC_KEY = "$USER[SSH_PUBLIC_KEY]"
    PASSWORD       = "asd"
  }

  disk {
    image_id = local.instances[each.key].image_id
  }

  nic {
    model      = "virtio"
    network_id = data.opennebula_virtual_network.service.id
  }

  graphics {
    keymap = "en-us"
    listen = "0.0.0.0"
    type   = "VNC"
  }
}
