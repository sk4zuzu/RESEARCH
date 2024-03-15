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
  files = {
    "onewg.yml" = {
      path    = "/var/tmp/onewg.yml"
      content = <<-YAML
        ---
        wg0:
          endpoint: 10.2.11.86:51820
          peer_subnet: 192.168.144.0/24
          server_port: 51820
          private_key: iIkUOhFQCFjZbPEkhFgQR2Hv0FfjejSX4Vv686II62E=
          interface_out: eth0
          peers:
            alice:
              address: 192.168.144.2/24
              preshared_key: 5/OipxpAqN8UXpaILlWhaSQ/np8DcxIul+iRXiIq8DI=
              private_key: iKVZgfL4BtNtWEdszoMLneB2AruyBPvbhBam7Fnzuks=
              allowed_ips:
              - 0.0.0.0/0
            chad:
              address: 192.168.144.4/24
              preshared_key: GUrRMZCLqb/LJWxvFFPuS5coTxsJsJnqtIvv+XwVbgw=
              public_key: 8I/tnjP5lrnLqPny+Brp3p8qV6kWPQMMM2NY3yXnNEw=
              allowed_ips:
              - 0.0.0.0/0
            bob:
              address: 192.168.144.3/24
              preshared_key: kqMcuMd81Dfnw1VNsgctOwntBulo++FxV5TF6Nh6Zvs=
              private_key: eIB2AQHrM5UGzb7gO8D8goqgLpX6irKqoluzh4gt6nE=
              allowed_ips:
              - 0.0.0.0/0
      YAML
    }
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
        distro       = "service_VRouter"
        start_script = <<-BASH
          set -e
          apk --no-cache add mc ripgrep vim
        BASH
      }
      wg2 = {
        distro       = "service_VRouter"
        start_script = <<-BASH
          set -e
          apk --no-cache add mc ripgrep vim
        BASH
      }
    }
    vm = {
      vm1 = {
        distro       = "alpine318"
        network      = "service"
        start_script = <<-BASH
          set -e
          apk --no-cache add mc ripgrep wireguard-tools-wg-quick vim

          install -o 0 -g 0 -m u=rw,go= -D /dev/fd/0 /etc/wireguard/wg0.conf <<'INI'
          [Interface]
          Address    = 192.168.144.4/24
          ListenPort = 51820
          PrivateKey = 8NyK+uwCK0Um66UfrpC3psg3omActcCy2l15bdb2xEE=

          [Peer]
          Endpoint     = 10.2.11.86:51820
          PublicKey    = GYi0NOfvIJiWKQUhvcemcAihYSoLT4o6NpUMWsy8Nl0=
          PresharedKey = GUrRMZCLqb/LJWxvFFPuS5coTxsJsJnqtIvv+XwVbgw=
          AllowedIPs   = 0.0.0.0/0
          INI
        BASH
      }
      vm2 = {
        distro       = "alpine318"
        network      = "private"
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

resource "terraform_data" "files" {
  for_each = local.files

  triggers_replace = [md5(each.value.content)]

  connection {
    type  = "ssh"
    user  = "ubuntu"
    host  = "10.2.11.40"
    agent = true
  }

  provisioner "file" {
    destination = each.value.path
    content     = each.value.content
  }
}

resource "opennebula_image" "files" {
  lifecycle {
    replace_triggered_by = [terraform_data.files]
  }

  for_each     = local.files
  name         = each.key
  datastore_id = "2"
  type         = "CONTEXT"
  permissions  = "642"
  path         = each.value.path
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
    TOKEN        = "NO"
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
    FILES_DS = join(" ", [
      for k, _ in local.files : "$FILE[IMAGE_ID=\"${opennebula_image.files[k].id}\"]"
    ])

    START_SCRIPT_BASE64 = base64encode(each.value.start_script)

    ONEAPP_VROUTER_ETH0_VIP0 = "10.2.11.86"

    ONEAPP_VNF_NAT4_ENABLED        = "YES"
    ONEAPP_VNF_NAT4_INTERFACES_OUT = "eth0"

    ONEAPP_VNF_WG_ENABLED        = "YES"
    ONEAPP_VNF_WG_INTERFACES_OUT = "eth0"
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

resource "opennebula_virtual_machine" "vm" {
  depends_on = [
    opennebula_virtual_router_nic.eth0,
    opennebula_virtual_router_nic.eth1,
  ]

  for_each    = local.instances.vm
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

    SSH_PUBLIC_KEY = "$USER[SSH_PUBLIC_KEY]"
    PASSWORD       = "asd"

    START_SCRIPT_BASE64 = base64encode(each.value.start_script)
  }

  disk {
    image_id = opennebula_image.images[each.value.distro].id
  }

  nic {
    network_id = data.opennebula_virtual_network.vnets[each.value.network].id
  }

  graphics {
    keymap = "en-us"
    listen = "0.0.0.0"
    type   = "VNC"
  }
}
