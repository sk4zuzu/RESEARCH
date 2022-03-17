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
  type = list(object({
    name    = string
    mode    = string
    domain  = string
    subnet  = string
    macaddr = string
  }))
  default = [{
    name    = "d1nat"
    mode    = "nat"
    domain  = "d1nat.lvs"
    subnet  = "172.16.1.0/24"
    macaddr = "52:54:16:01:00:%02x"
  },{
    name    = "d1route"
    mode    = "route"
    domain  = "d1route.lvs"
    subnet  = "172.16.2.0/24"
    macaddr = "52:54:16:02:00:%02x"
  }]
}

variable "storage" {
  type = object({
    directory = string
    artifact  = string
  })
  default = {
    directory = "/stor/d1"
    artifact  = "./../../packer/.cache/output/packer-alpine.qcow2"
  }
}

provider "libvirt" {
  uri = "qemu+tcp://10.11.12.13/system"
}

resource "libvirt_pool" "d1" {
  name = "d1"
  type = "dir"
  path = var.storage.directory
}

resource "libvirt_volume" "d1" {
  name   = "d1"
  pool   = libvirt_pool.d1.name
  format = "qcow2"
  source = var.storage.artifact
}

resource "libvirt_network" "d1" {
  count     = length(var.network)
  name      = var.network[count.index].name
  mode      = var.network[count.index].mode
  domain    = var.network[count.index].domain
  addresses = [ var.network[count.index].subnet ]
}

resource "libvirt_cloudinit_disk" "d1" {
  name = "d1.iso"
  pool = libvirt_pool.d1.name

  meta_data = <<-EOF
  instance-id: d1
  local-hostname: d1
  EOF

  network_config = <<-EOF
  version: 2
  ethernets:
    eth0:
      addresses:
        - ${cidrhost(var.network[0].subnet, 10)}/${split("/", var.network[0].subnet)[1]}
      dhcp4: false
      dhcp6: false
      gateway4: ${cidrhost(var.network[0].subnet, 1)}
      macaddress: '${lower(format(var.network[0].macaddr, 10))}'
    eth1:
      addresses:
        - ${cidrhost(var.network[1].subnet, 10)}/${split("/", var.network[1].subnet)[1]}
      dhcp4: false
      dhcp6: false
      gateway4: ${cidrhost(var.network[1].subnet, 1)}
      macaddress: '${lower(format(var.network[1].macaddr, 10))}'
  EOF

  user_data = <<-EOF
  #cloud-config
  ssh_pwauth: false
  users:
    - name: alpine
      ssh_authorized_keys: "${chomp(file("~/.ssh/id_rsa.pub"))}"
    - name: root
      ssh_authorized_keys: "${chomp(file("~/.ssh/id_rsa.pub"))}"
  chpasswd:
    list:
      - 'alpine:asd'
    expire: false
  growpart:
    mode: auto
    devices: ['/']
  write_files:
    - content: |
        alpine ALL=(ALL:ALL) NOPASSWD:SETENV: ALL
      path: /etc/sudoers
    - content: |
        nameserver 1.1.1.1
      path: /etc/resolv.conf
    - content: |
        net.ipv4.ip_forward = 1
      path: /etc/sysctl.d/98-ip-forward.conf
  runcmd:
    - sysctl -p /etc/sysctl.d/98-ip-forward.conf
  EOF
}

resource "libvirt_domain" "d1" {
  name = "d1"

  cloudinit = libvirt_cloudinit_disk.d1.id

  vcpu   = var.resources.vcpu
  memory = var.resources.memory

  cpu {
    mode = "host-passthrough"
  }

  dynamic "network_interface" {
    for_each = var.network
    content {
      network_name   = network_interface.value["name"]
      wait_for_lease = false
    }
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
    volume_id = libvirt_volume.d1.id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
