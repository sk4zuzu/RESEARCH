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

resource "opennebula_datastore" "system_ceph" {
  name = "system_ceph"
  type = "system"

  bridge_list = ["10.11.12.13", "10.11.12.31"]

  ceph {
    host      = ["10.11.12.86:6789", "10.11.12.86:3300", "10.11.12.69:6789", "10.11.12.69:3300"]
    pool_name = "asd"
    user      = "asd"
    secret    = "asd"
  }
}

resource "opennebula_datastore" "image_ceph" {
  name = "image_ceph"
  type = "image"

  compatible_system_datastore = [opennebula_datastore.system_ceph.id, 86, "69"]

  bridge_list = ["10.11.12.13", "10.11.12.31"]

  ceph {
    host      = ["10.11.12.86:6789", "10.11.12.86:3300", "10.11.12.69:6789", "10.11.12.69:3300"]
    pool_name = "asd"
    user      = "asd"
    secret    = "asd"
  }
}
