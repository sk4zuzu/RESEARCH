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
  ssh_opts = "-o ForwardAgent=yes -o StrictHostKeyChecking=no -o GlobalKnownHostsFile=/dev/null -o UserKnownHostsFile=/dev/null"
  vips = {
    service = "10.2.11.86"
    private = "172.20.0.86"
  }
  distros = {
    alpine318 = {
      image_path = "http://10.2.11.30/images/export/alpine318.qcow2"
    }
    service_VRouter = {
      image_path = "http://10.2.11.30/images/export/service_VRouter.qcow2"
    }
  }
  instances = {
    wg = {
      wg1 = {
        start_script = <<-BASH
          set -e
          apk --no-cache add mc ripgrep vim
        BASH
      }
      wg2 = {
        start_script = <<-BASH
          set -e
          apk --no-cache add mc ripgrep vim
        BASH
      }
    }
    vm = {
      vm1 = {
        network      = "service"
        gateway      = null
        start_script = <<-BASH
          set -e
          apk --no-cache add mc ripgrep wireguard-tools-wg-quick vim
        BASH
      }
      vm2 = {
        network      = "private"
        gateway      = local.vips.private
        start_script = <<-BASH
          set -e
          apk --no-cache add mc ripgrep vim
        BASH
      }
    }
  }
}

data "opennebula_virtual_network" "vnets" {
  for_each = toset(["service", "private"])
  name     = each.key
}

resource "opennebula_image" "images" {
  for_each     = local.distros
  name         = each.key
  datastore_id = "1"
  persistent   = false
  permissions  = "642"
  dev_prefix   = "vd"
  driver       = "qcow2"
  path         = each.value.image_path
}

resource "opennebula_virtual_router_instance_template" "wg" {
  name        = "wg"
  permissions = "642"
  memory      = "1024"

  cpumodel {
    model = "host-passthrough"
  }
  cpu  = "0.5"
  vcpu = "1"

  os {
    arch = "x86_64"
    boot = ""
  }

  context = {
    SET_HOSTNAME = "$NAME"
    NETWORK      = "YES"
    TOKEN        = "YES"
    REPORT_READY = "NO"

    SSH_PUBLIC_KEY = "$USER[SSH_PUBLIC_KEY]"
    PASSWORD       = "asd"
  }

  disk {
    image_id = opennebula_image.images["service_VRouter"].id
  }

  graphics {
    keymap = "en-us"
    listen = "0.0.0.0"
    type   = "VNC"
  }
}

resource "opennebula_virtual_router" "wg" {
  name                 = "wg"
  permissions          = "642"
  instance_template_id = opennebula_virtual_router_instance_template.wg.id
}

resource "opennebula_virtual_router_instance" "wg" {
  for_each = local.instances.wg
  name     = each.key

  context = {
    START_SCRIPT_BASE64 = base64encode(each.value.start_script)

    ONEAPP_VROUTER_ETH0_VIP0 = local.vips.service
    ONEAPP_VROUTER_ETH1_VIP0 = local.vips.private

    ONEAPP_VNF_NAT4_ENABLED        = "YES"
    ONEAPP_VNF_NAT4_INTERFACES_OUT = "eth0"

    ONEAPP_VNF_DNS_ENABLED = "YES"

    ONEAPP_VNF_WG_ENABLED       = "YES"
    ONEAPP_VNF_WG_INTERFACE_OUT = "eth0"
    ONEAPP_VNF_WG_INTERFACE_IN  = "eth1"
  }

  virtual_router_id = opennebula_virtual_router.wg.id
}

resource "opennebula_virtual_router_nic" "eth0" {
  depends_on        = [opennebula_virtual_router_instance.wg]
  model             = "virtio"
  virtual_router_id = opennebula_virtual_router.wg.id
  network_id        = data.opennebula_virtual_network.vnets["service"].id
}

resource "opennebula_virtual_router_nic" "eth1" {
  depends_on        = [opennebula_virtual_router_nic.eth0]
  model             = "virtio"
  virtual_router_id = opennebula_virtual_router.wg.id
  network_id        = data.opennebula_virtual_network.vnets["private"].id
}

resource "opennebula_template" "vm" {
  name        = "vm"
  permissions = "642"
  memory      = "1024"

  cpumodel {
    model = "host-passthrough"
  }
  cpu  = "0.5"
  vcpu = "1"

  os {
    arch = "x86_64"
    boot = ""
  }

  context = {
    SET_HOSTNAME = "$NAME"
    NETWORK      = "YES"
    TOKEN        = "NO"
    REPORT_READY = "NO"

    SSH_PUBLIC_KEY = "$USER[SSH_PUBLIC_KEY]"
    PASSWORD       = "asd"
  }

  disk {
    image_id = opennebula_image.images["alpine318"].id
  }

  graphics {
    keymap = "en-us"
    listen = "0.0.0.0"
    type   = "VNC"
  }
}

resource "opennebula_virtual_machine" "vm1" {
  depends_on = [
    opennebula_virtual_router_nic.eth0,
    opennebula_virtual_router_nic.eth1,
  ]

  name        = "vm1"
  template_id = opennebula_template.vm.id

  context = {
    START_SCRIPT_BASE64 = base64encode(local.instances.vm.vm1.start_script)
  }

  template_section {
    name     = "NIC"
    elements = {
      NETWORK_ID = data.opennebula_virtual_network.vnets[local.instances.vm.vm1.network].id
    }
  }
}

resource "opennebula_virtual_machine" "vm2" {
  depends_on = [
    opennebula_virtual_router_nic.eth0,
    opennebula_virtual_router_nic.eth1,
  ]

  name        = "vm2"
  template_id = opennebula_template.vm.id

  context = {
    START_SCRIPT_BASE64 = base64encode(local.instances.vm.vm2.start_script)
  }

  template_section {
    name     = "NIC"
    elements = {
      NETWORK_ID = data.opennebula_virtual_network.vnets[local.instances.vm.vm2.network].id
      GATEWAY    = local.instances.vm.vm2.gateway
    }
  }
}

resource "terraform_data" "wg" {
  depends_on = [
    opennebula_virtual_machine.vm1,
    opennebula_virtual_machine.vm2,
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EXPRESSION
      sleep 30; \
      ssh ${local.ssh_opts} 'root@${local.vips.service}' "onegate vm show -j | jq -r '.VM.USER_TEMPLATE.ONEGATE_VNF_WG_PEER0|@base64d'" \
      | ssh ${local.ssh_opts} 'root@${opennebula_virtual_machine.vm1.template_nic[0].computed_ip}' 'install -m u=rw,go= -D /dev/fd/0 /etc/wireguard/wg0.conf && wg-quick up wg0'
    EXPRESSION
  }
}
