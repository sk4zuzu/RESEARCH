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
      network_id    = data.opennebula_virtual_network.service.id
      floating_ip   = true
      floating_only = true
    }
    eth1 = {
      network_id    = opennebula_virtual_network.reservation.id
      floating_ip   = true
      floating_only = false
    }
  }
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
  reservation_auto_gw  = true
  reservation_auto_dns = true
}

module "vrouter" {
  depends_on = [opennebula_virtual_network.reservation]
  source     = "./modules/vrouter/"
  instances  = 2
  nics       = local.nics
}

module "oneflow" {
  depends_on = [module.vrouter]
  source     = "./modules/oneflow/"
  network_id = local.nics["eth1"].network_id
}

#module "sdnat" {
#  depends_on = [module.oneflow]
#  source     = "./modules/sdnat/"
#  network_id = local.nics["eth1"].network_id
#}

/*
onevm nic-attach vr_sdnat <<'EOF'
NIC_ALIAS = [
  NETWORK_ID = "0",
  PARENT     = "NIC0",
  EXTERNAL   = "YES" ]
EOF
*/
