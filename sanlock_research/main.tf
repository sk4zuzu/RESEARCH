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
    sanlock_ubuntu2204 = {
      image_path = "http://10.2.11.30/images/export/ubuntu2204.qcow2"
    }
  }
  instances = {
    sanlock1 = {
      distro = "sanlock_ubuntu2204"
      start_script = <<-BASH
        set -e

        export DEBIAN_FRONTEND=noninteractive

        apt-get update -y
        apt-get install -y gawk mc vim
        apt-get install -y lvm2 lvm2-lockd sanlock

        gawk -i inplace -f- /etc/lvm/lvm.conf <<'AWK'
        {gsub(/[# ]*use_lvmlockd *=.*/, "use_lvmlockd = 1"); print}
        AWK

        gawk -i inplace -f- /etc/lvm/lvmlocal.conf <<'AWK'
        {gsub(/[# ]*host_id *=.*/, "host_id = 1"); print}
        AWK

        systemctl enable lvmlockd sanlock --now

        vgcreate --shared sanlock0 /dev/vdb

        lvcreate -l 100%VG -n data0 sanlock0

        mkfs.xfs /dev/sanlock0/data0

        install -d /data0/

        mount /dev/sanlock0/data0 /data0/
      BASH
    }
    sanlock2 = {
      distro = "sanlock_ubuntu2204"
      start_script = <<-BASH
        set -e

        export DEBIAN_FRONTEND=noninteractive

        apt-get update -y
        apt-get install -y gawk mc vim
        apt-get install -y lvm2 lvm2-lockd sanlock

        gawk -i inplace -f- /etc/lvm/lvm.conf <<'AWK'
        {gsub(/[# ]*use_lvmlockd *=.*/, "use_lvmlockd = 1"); print}
        AWK

        gawk -i inplace -f- /etc/lvm/lvmlocal.conf <<'AWK'
        {gsub(/[# ]*host_id *=.*/, "host_id = 1"); print}
        AWK

        systemctl enable lvmlockd sanlock --now

        for RETRY in 9 8 7 6 5 4 3 2 1 0; do
            if blkid /dev/vdb; then break; fi
            sleep 1
        done && [ "$RETRY" -gt 0 ]

        vgchange --lock-start

        install -d /data0/
      BASH
    }
  }
}

data "opennebula_virtual_network" "service" {
  name = "service"
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

resource "opennebula_image" "shareable" {
  name         = "sanlock"
  datastore_id = "1"
  type         = "DATABLOCK"
  persistent   = true
  permissions  = "642"
  dev_prefix   = "vd"
  size         = "10240"
  tags         = { PERSISTENT_TYPE = "shareable" }
}

resource "opennebula_virtual_machine" "machines" {
  for_each = local.instances

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

  disk {
    image_id = opennebula_image.shareable.id
  }

  nic {
    model      = "virtio"
    network_id = data.opennebula_virtual_network.service.id
  }

  graphics {
    keymap = "en-us"
    listen = "0.0.0.0"
    type   = "VNC"
  }
}
