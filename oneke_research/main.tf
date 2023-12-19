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
  nics = {
    eth0 = {
      network_id  = data.opennebula_virtual_network.oneke["service"].id
      floating_ip = true
    }
    eth1 = {
      network_id  = opennebula_virtual_network.oneke["reservation"].id
      floating_ip = true
    }
  }
}

data "opennebula_virtual_network" "oneke" {
  for_each = toset(["service", "private"])
  name     = each.key
}

resource "opennebula_virtual_network" "oneke" {
  for_each = toset(["reservation"])
  name     = each.key

  reservation_vnet    = data.opennebula_virtual_network.oneke["private"].id
  reservation_size    = 20
  reservation_ar_id   = 0
  reservation_auto_gw = true
}

module "vrouter" {
  source    = "./modules/vrouter/"
  instances = 2
  nics      = local.nics
}

module "oneflow" {
  depends_on = [module.vrouter]
  source     = "./modules/oneflow/"
  network_id = local.nics["eth1"].network_id
}
