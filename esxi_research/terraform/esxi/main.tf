terraform {
  required_version = "1.1.3"
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.6.12"
    }
  }
}

variable "instances" {
  type = list(string)
  default = [
    "esxi1",
    "esxi2",
  ]
}

variable "vcpu" {
  type    = string
  default = "2"
}

variable "memory" {
  type    = string
  default = "4096"
}

variable "pool_directory" {
  type    = string
  default = "/stor/libvirt/esxi"
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
        <xsl:value-of select="'vmxnet3'"/>
      </xsl:attribute>
    </xsl:template>

    <xsl:template match="/domain/devices/disk[@type='volume']/target/@bus">
      <xsl:attribute name="bus">
        <xsl:value-of select="'ide'"/>
      </xsl:attribute>
    </xsl:template>

    <xsl:template match="/domain/devices/disk[@type='volume']/target[@dev='vda']/@dev">
      <xsl:attribute name="dev">
        <xsl:value-of select="'hda'"/>
      </xsl:attribute>
    </xsl:template>

    <xsl:template match="/domain/devices/disk[@type='file']/target[@dev='hda']/@dev">
      <xsl:attribute name="dev">
        <xsl:value-of select="'hdb'"/>
      </xsl:attribute>
    </xsl:template>

  </xsl:stylesheet>
  EOF
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "esxi" {
  name = "esxi"
  type = "dir"
  path = var.pool_directory
}

resource "libvirt_volume" "esxi" {
  for_each = toset(var.instances)
  name     = each.key
  pool     = libvirt_pool.esxi.name
  source   = "./../../packer/esxi/.cache/output-${each.key}/packer-${each.key}.qcow2"
  format   = "qcow2"
}

resource "libvirt_domain" "esxi" {
  for_each = toset(var.instances)
  name     = each.key
  vcpu     = var.vcpu
  memory   = var.memory

  cpu {
    mode = "host-passthrough"
  }

  network_interface {
    network_name  = "vcsa"
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

  disk {
    volume_id = libvirt_volume.esxi[each.key].id
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
