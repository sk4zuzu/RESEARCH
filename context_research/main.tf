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
  distros = {
    context_alma8 = {
      image_path   = "http://10.2.11.30/images/export/alma8.qcow2"
      start_script = <<-BASH
        set -e

        install -o 0 -g 0 -m u=rwx,go=rx /dev/fd/0 /root/nm.sh <<NM
        nmcli con add con-name eth0 type ethernet ifname eth0
        nmcli con mod eth0 ipv4.method manual ipv4.addresses 10.2.11.200/24 ipv4.gateway 10.2.11.1 autoconnect yes
        nmcli con up eth0
        NM

        install -o 0 -g 0 -m u=rwx,go=rx /dev/fd/0 /root/networkd.sh <<NETWORKD
        cat >/etc/systemd/network/eth0.network <<EOF
        [Match]
        Name=eth0
        [Link]
        ActivationPolicy=always-up
        [Network]
        Address=10.2.11.200/24
        IPForward=ipv4
        IPMasquerade=no
        [Route]
        Gateway=10.2.11.1
        EOF
        networkctl reload
        NETWORKD
      BASH
    }
    context_alma9 = {
      image_path   = "http://10.2.11.30/images/export/alma9.qcow2"
      start_script = <<-BASH
        set -e

        install -o 0 -g 0 -m u=rwx,go=rx /dev/fd/0 /root/nm.sh <<NM
        nmcli con add con-name eth0 type ethernet ifname eth0
        nmcli con mod eth0 ipv4.method manual ipv4.addresses 10.2.11.201/24 ipv4.gateway 10.2.11.1 autoconnect yes
        nmcli con up eth0
        NM

        install -o 0 -g 0 -m u=rwx,go=rx /dev/fd/0 /root/networkd.sh <<NETWORKD
        cat >/etc/systemd/network/eth0.network <<EOF
        [Match]
        Name=eth0
        [Link]
        ActivationPolicy=always-up
        [Network]
        Address=10.2.11.201/24
        IPForward=ipv4
        IPMasquerade=no
        [Route]
        Gateway=10.2.11.1
        EOF
        networkctl reload
        NETWORKD
      BASH
    }
  }
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

resource "opennebula_virtual_network" "ether" {
  name            = "ether"
  permissions     = "642"
  bridge          = "br0"
  type            = "bridge"
  dns             = "10.2.11.40"
  gateway         = "10.2.11.1"
  network_address = "10.2.11.0"
  network_mask    = "255.255.255.0"
}

resource "opennebula_virtual_network_address_range" "ether" {
  virtual_network_id = opennebula_virtual_network.ether.id
  ar_type            = "ETHER"
  mac                = "02:00:01:02:03:04"
  size               = 16
}

resource "opennebula_virtual_machine" "machines" {
  depends_on = [
    opennebula_virtual_network.ether,
    opennebula_virtual_network_address_range.ether,
  ]

  for_each = local.distros

  name        = each.key
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

    ETH0_USER_MANAGED = "YES"

    SSH_PUBLIC_KEY = "$USER[SSH_PUBLIC_KEY]"
    PASSWORD       = "asd"

    NETCFG_TYPE = "nm"

    START_SCRIPT_BASE64 = base64encode(each.value.start_script)
  }

  disk {
    image_id = opennebula_image.images[each.key].id
  }

  nic {
    model      = "virtio"
    network_id = opennebula_virtual_network.ether.id
  }

  graphics {
    keymap = "en-us"
    listen = "0.0.0.0"
    type   = "VNC"
  }
}
