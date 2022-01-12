terraform {
  required_version = "1.1.3"
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.6.12"
    }
  }
}

variable "vcpu" {
  type    = string
  default = "2"
}

variable "memory" {
  type    = string
  default = "5120"
}

variable "pool_directory" {
  type    = string
  default = "/stor/libvirt/vcsa"
}

locals {
  xslt = <<-EOF
  <?xml version="1.0" ?>
  <xsl:stylesheet version="1.0"
                  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:output omit-xml-declaration="yes" indent="yes"/>
    <xsl:template match="node()|@*">
       <xsl:copy>
         <xsl:apply-templates select="node()|@*"/>
       </xsl:copy>
    </xsl:template>

    <xsl:template match="/domain/devices/interface[@type='network']/model/@type">
      <xsl:attribute name="type">
        <xsl:value-of select="'e1000'"/>
      </xsl:attribute>
    </xsl:template>

    <xsl:template match="/domain/devices/disk[@type='volume']/target/@bus">
      <xsl:attribute name="bus">
        <xsl:value-of select="'sata'"/>
      </xsl:attribute>
    </xsl:template>

  </xsl:stylesheet>
  EOF
  disks = {
    disk01 = "../../.cache/VCSA/VMware-vCenter-Server-Appliance-6.7.0.51000-18831133_OVF10-disk1.qcow2"
    disk02 = "../../.cache/VCSA/VMware-vCenter-Server-Appliance-6.7.0.51000-18831133_OVF10-disk2.qcow2"
    disk03 = "../../.cache/VCSA/VMware-vCenter-Server-Appliance-6.7.0.51000-18831133_OVF10-disk3.qcow2"
  }
  # MiB
  disks_empty = {
    disk04 = 25600
    disk05 = 10240
    disk06 = 10240
    disk07 = 15360
    disk08 = 10240
    disk09 = 1024
    disk10 = 10240
    disk11 = 10240
    disk12 = 102400
    disk13 = 51200
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_network" "vcsa" {
  name      = "vcsa"
  domain    = "poc.svc"
  mode      = "nat"
  addresses = [ "10.11.13.0/24" ]
  dhcp {
    enabled = true
  }
}

resource "libvirt_pool" "vcsa" {
  name = "vcsa"
  type = "dir"
  path = var.pool_directory
}

resource "libvirt_volume" "vcsa" {
  for_each = local.disks
  name     = each.key
  pool     = libvirt_pool.vcsa.name
  source   = each.value
  format   = "qcow2"
}

resource "libvirt_volume" "vcsa_empty" {
  for_each = local.disks_empty
  name     = each.key
  pool     = libvirt_pool.vcsa.name
  size     = each.value * pow(1024, 2)
  format   = "qcow2"
}

resource "libvirt_cloudinit_disk" "vcsa" {
  name = "vcsa.iso"
  pool = libvirt_pool.vcsa.name

  meta_data = <<-EOF
  instance-id: iid-local01
  local-hostname: vcsa
  EOF

  user_data = <<-EOF
  fqdn: vcsa.poc.svc
  hostname: vcsa
  write_files:
    - path: /etc/systemd/network/10-static.network
      permissions: 0644
      content: |
        [Match]
        Name=eth0
        [Network]
        Address=10.11.13.86/24
        Gateway=10.11.13.1
        DNS=1.1.1.1
        DHCP=no
        Domains=poc.svc
        LinkLocalAddressing=no
        LLDP=true
    - path: /etc/systemd/network/99-dhcp-en.network
      permissions: 0644
      content: |
        [Match]
        Name=e*
        [Network]
        DHCP=no
  EOF
}

resource "libvirt_domain" "vcsa" {
  name   = "vcsa"
  vcpu   = var.vcpu
  memory = var.memory

  #cloudinit = libvirt_cloudinit_disk.vcsa.id

  cpu {
    mode = "host-passthrough"
  }

  network_interface {
    network_id     = libvirt_network.vcsa.id
    wait_for_lease = false
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  dynamic "disk" {
    for_each = local.disks
    content {
      volume_id = libvirt_volume.vcsa[disk.key].id
    }
  }

  dynamic "disk" {
    for_each = local.disks_empty
    content {
      volume_id = libvirt_volume.vcsa_empty[disk.key].id
    }
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  xml {
    xslt = local.xslt
  }
}
