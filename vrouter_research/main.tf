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

data "opennebula_virtual_network" "maconly" {
  name = "maconly"
}

resource "opennebula_image" "router" {
  name         = "router"
  datastore_id = "1"
  persistent   = false
  permissions  = "642"
  dev_prefix   = "vd"
  driver       = "qcow2"
  #path         = "http://10.2.11.1/images/service_VRouter.qcow2"
  path         = "https://marketplace.opennebula.io//appliance/883d974f-f30e-4fc8-aa06-e1af2a020e49/download/0"
}

resource "opennebula_image" "backend" {
  name         = "backend"
  datastore_id = "1"
  persistent   = false
  permissions  = "642"
  dev_prefix   = "vd"
  driver       = "qcow2"
  path         = "http://10.2.11.1/images/alpine320.qcow2"
}

resource "opennebula_virtual_router_instance_template" "router" {
  name        = "router"
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

    # DNS

    ONEAPP_VNF_DNS_ENABLED    = "YES"
    ONEAPP_VNF_DNS_INTERFACES = "eth1"

    # DHCP4v2

    ONEAPP_VNF_DHCP4_ENABLED    = "YES"
    ONEAPP_VNF_DHCP4_INTERFACES = "eth1"
  }

  os {
    arch = "x86_64"
    boot = ""
  }

  disk {
    image_id = opennebula_image.router.id
  }

  graphics {
    keymap = "en-us"
    listen = "0.0.0.0"
    type   = "VNC"
  }
}

resource "opennebula_virtual_router" "router" {
  name        = "router"
  permissions = "642"

  instance_template_id = opennebula_virtual_router_instance_template.router.id
}

resource "opennebula_virtual_router_instance" "router" {
  count       = 2
  name        = "router_${count.index}"
  permissions = "642"
  memory      = "512"
  cpu         = "0.5"

  virtual_router_id = opennebula_virtual_router.router.id
}

resource "opennebula_virtual_router_nic" "eth0" {
  depends_on = [
    opennebula_virtual_router_instance.router,
  ]

  model       = "virtio"
  floating_ip = true

  virtual_router_id = opennebula_virtual_router.router.id
  network_id        = data.opennebula_virtual_network.service.id
}

resource "opennebula_virtual_router_nic" "eth1" {
  depends_on = [
    opennebula_virtual_router_instance.router,
    opennebula_virtual_router_nic.eth0,
  ]

  model       = "virtio"
  floating_ip = true

  virtual_router_id = opennebula_virtual_router.router.id
  network_id        = data.opennebula_virtual_network.private.id
}

resource "opennebula_template" "backend" {
  name        = "backend"
  permissions = "642"
  cpu         = "0.5"
  vcpu        = "1"
  memory      = "512"

  context = {
    SET_HOSTNAME = "$NAME"
    NETWORK      = "YES"
    TOKEN        = "YES"
    REPORT_READY = "YES"
    BACKEND      = "YES"

    SSH_PUBLIC_KEY = "$USER[SSH_PUBLIC_KEY]"
    PASSWORD       = "asd"
  }

  os {
    arch = "x86_64"
    boot = ""
  }

  disk {
    image_id = opennebula_image.backend.id
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
            name                 = "backend"
            cardinality          = 1
            min_vms              = 1
            cooldown             = 5
            elasticity_policies  = []
            scheduled_policies   = []
            vm_template          = tonumber(opennebula_template.backend.id)
            vm_template_contents = <<-TEMPLATE
              NIC = [
                METHOD     = "dhcp",
                NAME       = "_NIC0",
                NETWORK_ID = "$maconly" ]
            TEMPLATE
          },
        ]
        networks = {
          service = "M|network|service||id:${data.opennebula_virtual_network.service.id}"
          maconly = "M|network|maconly||id:${data.opennebula_virtual_network.maconly.id}"
        }
      }
    }
  })
}

resource "opennebula_service" "service" {
  depends_on = [
    opennebula_virtual_router_nic.eth0,
    opennebula_virtual_router_nic.eth1,
  ]

  name = "service"

  template_id = opennebula_service_template.service.id

  extra_template = jsonencode({
      roles = [{ cardinality = 2 }]
  })

  timeouts {
    create = "15m"
    delete = "5m"
  }
}
