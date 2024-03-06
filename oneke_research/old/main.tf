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
      network_id = data.opennebula_virtual_network.service.id
    }
    eth1 = {
      network_id = data.opennebula_virtual_network.private.id
    }
  }
}

data "opennebula_virtual_network" "service" {
  name = "service"
}

data "opennebula_virtual_network" "private" {
  name = "private"
}

module "oneflow" {
  source     = "./modules/oneflow/"
  nics       = local.nics
}
