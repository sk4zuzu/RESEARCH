SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

NAME := alpine

RELEASE  := 3.15
ARTIFACT := alpine-virt-$(RELEASE).0-x86_64.iso

CHECKSUM := e97eaedb3bff39a081d1d7e67629d5c0e8fb39677d6a9dd1eaf2752e39061e02

CPUS      ?= 1
MEMORY    ?= 2048
DISK_SIZE ?= 10240

PACKER     := packer
PACKER_LOG ?= 1
HEADLESS   ?= true

define PACKERFILE
source "qemu" "$(NAME)" {
  accelerator = "kvm"

  disk_image   = false
  iso_url      = "https://dl-cdn.alpinelinux.org/alpine/v$(RELEASE)/releases/x86_64/$(ARTIFACT)"
  iso_checksum = "$(CHECKSUM)"

  memory    = "$(MEMORY)"
  disk_size = "$(DISK_SIZE)"

  net_device     = "virtio-net"
  disk_interface = "virtio"

  ssh_username     = "root"
  ssh_password     = "asd"
  shutdown_command = "/sbin/poweroff"

  output_directory = "$(SELF)/.cache/output/"
  vm_name          = "packer-$(NAME).qcow2"

  headless = $(HEADLESS)

  boot_wait = "10s"

  boot_command = [
    "root<enter><wait1s>",

    "setup-hostname alpine<enter>",

    "cat >/etc/network/interfaces <<EOF<enter>",
    "auto lo<enter>",
    "iface lo inet loopback<enter>",
    "auto eth0<enter>",
    "iface eth0 inet dhcp<enter>",
    "EOF<enter>",

    "cat >/etc/resolv.conf <<EOF<enter>",
    "nameserver 1.1.1.1<enter>",
    "EOF<enter>",

    "rc-service networking start<enter>",
    "rc-update add networking boot<enter>",

    "cat >/etc/apk/repositories <<EOF<enter>",
    "http://dl-cdn.alpinelinux.org/alpine/v$(RELEASE)/main<enter>",
    "http://dl-cdn.alpinelinux.org/alpine/v$(RELEASE)/community<enter>",
    "EOF<enter>",

    "apk --no-cache add bash openssh openssh-server-pam<enter>",
    "echo PermitRootLogin yes >>/etc/ssh/sshd_config<enter>",
    "rc-service sshd start<enter>",
    "rc-update add sshd<enter>",

    "passwd root <<EOF<enter>",
    "asd<enter>",
    "asd<enter>",
    "asd<enter>",
    "EOF<enter>",
  ]
}
build {
  sources = ["source.qemu.$(NAME)"]
  provisioner "shell" {
    execute_command = "bash --login {{.Path}}"
    scripts = [
      "remote-exec/01-basics.sh",
      "remote-exec/02-modules.sh",
      "remote-exec/03-libvirt.sh",
      "remote-exec/50-setup.sh",
    ]
  }
}
endef

export

.PHONY: all

all: build

.PHONY: build

build: $(SELF)/.cache/output/packer-$(NAME).qcow2

$(SELF)/.cache/output/packer-$(NAME).qcow2: Makefile $(wildcard $(SELF)/remote-exec/*.sh)
	mkdir -p $(SELF)/.cache/
	if ! [[ -e $(SELF)/.cache/build.pkr.hcl ]]; then ln -s /dev/stdin $(SELF)/.cache/build.pkr.hcl; fi
	$(PACKER) build -force $(SELF)/.cache/build.pkr.hcl <<< "$$PACKERFILE"

.PHONY: clean

clean:
	-rm -rf $(SELF)/.cache/
