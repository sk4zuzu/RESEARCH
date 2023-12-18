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
  networks = ["service", "private"]
  nics = {
    eth0 = {
      network_id  = data.opennebula_virtual_network.oneke["service"].id
      floating_ip = true
    }
    eth1 = {
      network_id  = data.opennebula_virtual_network.oneke["private"].id
      floating_ip = false
    }
  }
}

data "opennebula_virtual_network" "oneke" {
  for_each = toset(local.networks)
  name     = each.key
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
