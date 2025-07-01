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

resource "opennebula_virtual_network" "asd" {
  name              = "asd"
  permissions       = "660"
  group             = "oneadmin"
  type              = "ovswitch"
  bridge            = "ovs-pub"
  #vlan_id           = 1458
  automatic_vlan_id = false
}
