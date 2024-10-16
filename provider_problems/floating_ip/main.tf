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
  name                 = "reservation"
  reservation_vnet     = data.opennebula_virtual_network.private.id
  reservation_size     = 20
  reservation_ar_id    = 0
  reservation_first_ip = "172.20.0.123"
}

locals {
  images = {
    vr = "https://marketplace.opennebula.io//appliance/cc96d537-f6c7-499f-83f1-15ac4058750e/download/0"
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

resource "opennebula_virtual_router_instance_template" "asd" {
  name        = "vr"
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

    # NAT4

    ONEAPP_VNF_NAT4_ENABLED        = "YES"
    ONEAPP_VNF_NAT4_INTERFACES_OUT = "eth0"
  }

  os {
    arch = "x86_64"
    boot = ""
  }

  disk {
    image_id = opennebula_image.asd["vr"].id
  }

  graphics {
    keymap = "en-us"
    listen = "0.0.0.0"
    type   = "VNC"
  }
}

resource "opennebula_virtual_router" "asd" {
  name        = "vr"
  permissions = "642"

  instance_template_id = opennebula_virtual_router_instance_template.asd.id
}

resource "opennebula_virtual_router_instance" "asd" {
  count       = 2
  name        = "vr${count.index}.asd"
  permissions = "642"
  memory      = "512"
  cpu         = "0.5"

  virtual_router_id = opennebula_virtual_router.asd.id
}

resource "opennebula_virtual_router_nic" "eth0" {
  depends_on = [
    opennebula_virtual_router_instance.asd,
  ]

  model         = "virtio"
  floating_ip   = true
  floating_only = true

  virtual_router_id = opennebula_virtual_router.asd.id
  network_id        = data.opennebula_virtual_network.service.id
}

resource "opennebula_virtual_router_nic" "eth1" {
  depends_on = [
    opennebula_virtual_router_instance.asd,
    opennebula_virtual_router_nic.eth0,
  ]

  model         = "virtio"
  floating_ip   = true
  floating_only = false

  virtual_router_id = opennebula_virtual_router.asd.id
  network_id        = opennebula_virtual_network.reservation.id
}

resource "opennebula_virtual_machine" "asd" {
  depends_on = [
    opennebula_virtual_router_nic.eth0,
    opennebula_virtual_router_nic.eth1,
  ]

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
    network_id = opennebula_virtual_network.reservation.id
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
