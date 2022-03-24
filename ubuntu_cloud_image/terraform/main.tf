terraform {
  required_version = ">= 1.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.14"
    }
  }
}

variable "resources" {
  type = object({
    vcpu   = string
    memory = string
  })
  default = {
    vcpu   = "1"
    memory = "1024"
  }
}

variable "network" {
  type = object({
    mode    = string
    domain  = string
    subnet  = string
    macaddr = string
  })
  default = {
    mode    = "nat"
    domain  = "uci.lh"
    subnet  = "10.11.12.0/24"
    macaddr = "52:54:11:12:00:%02x"
  }
}

variable "storage" {
  type = object({
    directory = string
    artifact  = string
  })
  default = {
    directory = "/stor/uci"
    artifact  = "./../packer/.cache/output/packer-ubuntu.qcow2"
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "uci" {
  name = "uci"
  type = "dir"
  path = var.storage.directory
}

resource "libvirt_volume" "uci" {
  name   = "uci"
  pool   = libvirt_pool.uci.name
  format = "qcow2"
  source = var.storage.artifact
}

resource "libvirt_network" "uci" {
  name      = "uci"
  mode      = var.network.mode
  domain    = var.network.domain
  addresses = [ var.network.subnet ]
}

resource "libvirt_cloudinit_disk" "uci" {
  name = "uci.iso"
  pool = libvirt_pool.uci.name

  meta_data = <<-EOF
  instance-id: uci
  local-hostname: uci
  EOF

  network_config = <<-EOF
  version: 2
  ethernets:
    eth0:
      addresses:
        - ${cidrhost(var.network.subnet, 13)}/${split("/", var.network.subnet)[1]}
      dhcp4: false
      dhcp6: false
      gateway4: ${cidrhost(var.network.subnet, 1)}
      macaddress: '${lower(format(var.network.macaddr, 13))}'
  EOF

  user_data = <<-EOF
  #cloud-config
  ssh_pwauth: false
  users:
    - name: ubuntu
      ssh_authorized_keys: "${chomp(file("~/.ssh/id_rsa.pub"))}"
    - name: root
      ssh_authorized_keys: "${chomp(file("~/.ssh/id_rsa.pub"))}"
  chpasswd:
    list:
      - 'ubuntu:ubuntu'
    expire: false
  growpart:
    mode: auto
    devices: ['/']
  write_files:
    - content: |
        ubuntu ALL=(ALL:ALL) NOPASSWD:SETENV: ALL
      path: /etc/sudoers
    - content: |
        nameserver 1.1.1.1
      path: /etc/resolv.conf
  EOF
}

resource "libvirt_domain" "uci" {
  name = "uci"

  cloudinit = libvirt_cloudinit_disk.uci.id

  vcpu   = var.resources.vcpu
  memory = var.resources.memory

  cpu {
    mode = "host-passthrough"
  }

  network_interface {
    network_id     = libvirt_network.uci.id
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
    volume_id = libvirt_volume.uci.id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
