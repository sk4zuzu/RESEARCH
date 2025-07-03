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
  for_each = { service = null, private = null }
  name     = each.key
}

resource "opennebula_image" "asd" {
  for_each = {
    vr  = "http://10.2.11.1/images/service_VRouter.qcow2"
    a9  = "http://10.2.11.1/images/AlmaLinux-9-GenericCloud-9.6-20250522.x86_64.qcow2"
    u24 = "http://10.2.11.1/images/ubuntu-24.04-server-cloudimg-amd64.img"
  }
  name         = "dhcp-${each.key}-${random_id.asd.id}"
  datastore_id = "1"
  persistent   = false
  permissions  = "642"
  dev_prefix   = "vd"
  driver       = "qcow2"
  path         = each.value
}

resource "opennebula_virtual_router_instance_template" "asd" {
  for_each = { vr = null }

  name        = "dhcp-${each.key}-${random_id.asd.id}"
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

    ONEAPP_VNF_DNS_ENABLED         = "YES"
    ONEAPP_VNF_DNS_INTERFACES      = "eth1"
    ONEAPP_VNF_DNS_USE_ROOTSERVERS = "NO"
    ONEAPP_VNF_DNS_NAMESERVERS     = "1.1.1.1 8.8.8.8"

    # DHCP4v2

    ONEAPP_VNF_DHCP4_ENABLED    = "YES"
    ONEAPP_VNF_DHCP4_INTERFACES = "eth1"
    ONEAPP_VNF_DHCP4_GATEWAY    = "<ETH1_EP0>"
    ONEAPP_VNF_DHCP4_DNS        = "<ETH1_EP0>"
  }

  os {
    arch = "x86_64"
    boot = ""
  }

  disk {
    image_id = opennebula_image.asd[each.key].id
  }

  graphics {
    keymap = "en-us"
    listen = "0.0.0.0"
    type   = "VNC"
  }
}

resource "opennebula_virtual_router" "asd" {
  for_each = { vr = null }

  name        = "dhcp-${each.key}-${random_id.asd.id}"
  permissions = "642"

  instance_template_id = opennebula_virtual_router_instance_template.asd[each.key].id
}

resource "opennebula_virtual_router_instance" "asd" {
  for_each = { vr = null }

  name        = "dhcp-${each.key}-${random_id.asd.id}"
  permissions = "642"
  memory      = "512"
  cpu         = "0.5"

  virtual_router_id = opennebula_virtual_router.asd[each.key].id
}

resource "opennebula_virtual_router_nic" "eth0" {
  depends_on = [
    opennebula_virtual_router_instance.asd,
  ]

  model = "virtio"

  floating_ip   = true
  floating_only = true

  virtual_router_id = opennebula_virtual_router.asd["vr"].id
  network_id        = data.opennebula_virtual_network.asd["service"].id
}

resource "opennebula_virtual_router_nic" "eth1" {
  depends_on = [
    opennebula_virtual_router_instance.asd,
    opennebula_virtual_router_nic.eth0,
  ]

  model = "virtio"

  floating_ip   = true
  floating_only = false

  virtual_router_id = opennebula_virtual_router.asd["vr"].id
  network_id        = data.opennebula_virtual_network.asd["private"].id
}

locals {
  user_data = {
    a9 = {
      write_files = [
        {
          path        = "/etc/cloud/cloud.cfg.d/99_dhcp.cfg"
          owner       = "root:root"
          permissions = "644"
          content     = "network: { config: disabled }"
        },
        {
          path        = "/etc/sysconfig/network-scripts/ifcfg-eth0"
          owner       = "root:root"
          permissions = "644"
          content     = <<-IFCFG
            BOOTPROTO=dhcp
            DEVICE=eth0
            ONBOOT=yes
          IFCFG
        },
      ]
      runcmd = [
        ["/sbin/reboot"],
      ]
    }
    u24 = {
      write_files = [
        {
          path        = "/etc/cloud/cloud.cfg.d/99_dhcp.cfg"
          owner       = "root:root"
          permissions = "644"
          content     = "network: { config: disabled }"
        },
        {
          path        = "/etc/netplan/50-dhcp.yaml"
          owner       = "root:root"
          permissions = "644"
          content     = <<-YAML
            network:
              version: 2
              ethernets:
                ens3:
                  dhcp4: true
          YAML
        },
      ]
      bootcmd = [
        ["/usr/bin/rm", "-f", "/etc/netplan/50-cloud-init.yaml"],
      ]
      runcmd = [
        ["/usr/sbin/reboot"],
      ]
    }
  }
}

resource "opennebula_template" "asd" {
  for_each = {
    a9  = null
    u24 = null
  }

  name        = "dhcp-${each.key}-${random_id.asd.id}"
  permissions = "642"
  cpu         = "0.5"
  vcpu        = "1"
  memory      = "3072"

  cpumodel {
    model = "host-passthrough"
  }

  context = {
    SET_HOSTNAME = "$NAME"
    NETWORK      = "YES"
    TOKEN        = "YES"
    REPORT_READY = "NO"
    BACKEND      = "YES"

    SSH_PUBLIC_KEY = "$USER[SSH_PUBLIC_KEY]"
    PASSWORD       = "asd"

    USER_DATA_ENCODING = "base64"
    USER_DATA          = base64encode(join("\n", ["#cloud-config", yamlencode(local.user_data[each.key])]))
  }

  os {
    arch = "x86_64"
    boot = ""
  }

  disk {
    image_id = opennebula_image.asd[each.key].id
    size     = 12288
  }

  graphics {
    keymap = "en-us"
    listen = "0.0.0.0"
    type   = "VNC"
  }
}

resource "opennebula_virtual_machine" "asd" {
  depends_on = [
    opennebula_virtual_router_nic.eth0,
    opennebula_virtual_router_nic.eth1,
  ]

  for_each = {
    f1 = "u24"
    n1 = "a9"
    n2 = "u24"
  }

  name        = "dhcp-${each.key}-${random_id.asd.id}"
  template_id = opennebula_template.asd[each.value].id

  nic {
    network_id = data.opennebula_virtual_network.asd["private"].id
  }
}
