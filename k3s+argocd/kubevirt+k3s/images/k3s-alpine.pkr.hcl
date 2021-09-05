variable "alpine_version" {
  type = object({
    short = string
    long  = string
    arch  = string
  })
  default = {
    long  = env("ALPINE_VER_LONG")
    short = env("ALPINE_VER_SHORT")
    arch  = env("ALPINE_VER_ARCH")
  }
}

variable "headless" {
  type    = bool
  default = env("HEADLESS")
}

source "qemu" "alpine" {
  iso_url          = "https://dl-cdn.alpinelinux.org/alpine/v${var.alpine_version.short}/releases/${var.alpine_version.arch}/alpine-virt-${var.alpine_version.long}-${var.alpine_version.arch}.iso"
  iso_checksum     = "sha256:fcba6ecc8419da955d326a12b2f6d9d8f885a420a1112e0cf1910914c4c814a7"
  output_directory = "output_alpine-${var.alpine_version.long}-${var.alpine_version.arch}"
  shutdown_command = "echo packer | sudo -S shutdown -P now"
  disk_size        = "5000M"
  format           = "qcow2"
  accelerator      = "kvm"
  vm_name          = "alpine-${var.alpine_version.long}-${var.alpine_version.arch}.qcow2"
  net_device       = "virtio-net"
  disk_interface   = "virtio"
  communicator     = "none"
  headless         = var.headless
  boot_wait        = "10s"
  boot_command = [
    "root<enter><wait1s>",

    "set -o pipefail<enter>",

    "setup-keymap us us<enter>",
    "setup-hostname alpine<enter>",

    "cat >/etc/network/interfaces <<EOF<enter>",
    "auto lo<enter>",
    "iface lo inet loopback<enter>",
    "auto eth0<enter>",
    "iface eth0 inet dhcp<enter>",
    "EOF<enter>",

    "cat >/etc/resolv.conf <<EOF<enter>",
    "nameserver 8.8.8.8<enter>",
    "EOF<enter>",

    "rc-service networking start<enter>",
    "rc-update add networking boot<enter>",

    "setup-timezone<enter>",
    "UTC<enter>",

    "cat >/etc/apk/repositories <<EOF<enter>",
    "http://dl-cdn.alpinelinux.org/alpine/v${var.alpine_version.short}/main<enter>",
    "http://dl-cdn.alpinelinux.org/alpine/v${var.alpine_version.short}/community<enter>",
    "EOF<enter>",

    "apk --no-cache add dropbear<enter>",
    "rc-service dropbear start<enter>",
    "rc-update add dropbear<enter>",

    "apk --no-cache add openntpd<enter>",
    "rc-service openntpd start<enter>",
    "rc-update add openntpd<enter>",

    "apk --no-cache add cloud-init<enter>",
    "setup-cloud-init<enter>",

    "yes | setup-disk -m sys /dev/vda<enter>",

    "sync<enter>",
    "poweroff<enter>",
	]
}

build {
  sources = ["source.qemu.alpine"]
}
