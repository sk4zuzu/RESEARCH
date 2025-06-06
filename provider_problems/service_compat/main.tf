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

resource "random_id" "asd" {
  byte_length = 4
}

data "opennebula_virtual_network" "asd" {
  for_each = { service = null }
  name     = each.key
}

resource "opennebula_image" "asd" {
  for_each     = { alpine321 = "https://marketplace.opennebula.io//appliance/9ea07f80-beb8-013d-a75b-7875a4a4f528/download/0" }
  name         = "${each.key}-${random_id.asd.id}"
  datastore_id = "1"
  persistent   = false
  permissions  = "642"
  dev_prefix   = "vd"
  driver       = "qcow2"
  path         = each.value
}

resource "opennebula_template" "asd" {
  for_each    = { role1 = opennebula_image.asd["alpine321"].id }
  name        = "${each.key}-${random_id.asd.id}"
  permissions = "642"
  cpu         = "0.5"
  vcpu        = "1"
  memory      = "2048"

  context = {
    NETWORK        = "YES"
    TOKEN          = "YES"
    SSH_PUBLIC_KEY = "$USER[SSH_PUBLIC_KEY]"
  }

  os {
    arch = "x86_64"
    boot = ""
  }

  disk {
    image_id = each.value
  }

  graphics {
    keymap = "en-us"
    listen = "0.0.0.0"
    type   = "VNC"
  }
}

resource "opennebula_service_template" "asd" {
  for_each    = { service = opennebula_template.asd["role1"].id }
  name        = "${each.key}-${random_id.asd.id}"
  permissions = "642"

  template = jsonencode({
    TEMPLATE = {
      BODY = {
        name       = "${each.key}-${random_id.asd.id}"
        deployment = "straight"
        roles = [
          {
            name                = "role1"
            cardinality         = 1
            min_vms             = 1
            cooldown            = 5
            elasticity_policies = []
            scheduled_policies  = []

            # PROBLEM 1 (CANNOT BE REMOVED)
            type = "vm"

            # PROBLEM 2 (FAILS)
            # vm_template = tonumber(each.value)

            # PROBLEM 3 (NO EFFECT)
            # template_id          = tonumber(each.value)
            # vm_template_contents = <<-TEMPLATE
            #   NIC = [ NETWORK_ID = ${data.opennebula_virtual_network.asd["service"].id} ]
            # TEMPLATE

            # PROBLEM 4 (FAILS)
            template_id       = tonumber(each.value)
            template_contents = { NIC = [{ NETWORK_ID = data.opennebula_virtual_network.asd["service"].id }] }
          },
        ]
      }
    }
  })
}

resource "opennebula_service" "asd" {
  for_each = { service = opennebula_service_template.asd["service"].id }
  name     = "${each.key}-${random_id.asd.id}"

  template_id = each.value

  extra_template = jsonencode({
    roles = [{ cardinality = 1 }]
  })

  timeouts {
    create = "5m"
    delete = "5m"
  }
}
