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

resource "opennebula_image" "vm" {
  name         = "vm"
  datastore_id = "1"
  persistent   = false
  permissions  = "642"
  dev_prefix   = "vd"
  driver       = "qcow2"
  path         = "https://marketplace.opennebula.io//appliance/d74a5f80-20bd-013d-0e49-7875a4a4f528/download/0"
}

resource "opennebula_template" "vm" {
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

  os {
    arch = "x86_64"
    boot = ""
  }

  disk {
    image_id = opennebula_image.vm.id
  }

  graphics {
    keymap = "en-us"
    listen = "0.0.0.0"
    type   = "VNC"
  }
}

resource "opennebula_service_template" "service" {
  name        = "service"
  permissions = "642"

  template = jsonencode({
    TEMPLATE = {
      BODY = {
        name       = "service"
        deployment = "straight"
        roles = [
          {
            name                 = "vm"
            cardinality          = 2
            min_vms              = 1
            cooldown             = 5
            elasticity_policies  = []
            scheduled_policies   = []
            vm_template          = tonumber(opennebula_template.vm.id)
            vm_template_contents = <<-TEMPLATE
              NIC = [
                NAME       = "_NIC0",
                NETWORK_ID = "$test1" ]
            TEMPLATE
          },
        ]
        networks = {
          test1 = "M|network|test1| |reserve_from:${data.opennebula_virtual_network.service.id}:SIZE=6"
        }
      }
    }
  })
}

resource "opennebula_service" "service" {
  name = "service"

  template_id = opennebula_service_template.service.id

  extra_template = jsonencode({
      networks_values = [{
        test1 = {
          reserve_from = data.opennebula_virtual_network.service.id,
          extra        = "NAME=Test1\nSIZE=6",
        }
      }]
  })

  timeouts {
    create = "15m"
    delete = "5m"
  }
}
