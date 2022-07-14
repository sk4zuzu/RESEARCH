SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

NAME := ubuntu

RELEASE  := 22.04/release-20220616
ARTIFACT := ubuntu-22.04-server-cloudimg-amd64.img
CHECKSUM := 8be55b6b21b0932245e5169fb532dae0e0ff3d541e2866e61ce12e7c38be8315

CPUS      ?= 1
MEMORY    ?= 2048
DISK_SIZE ?= 10240

PACKER     := packer
PACKER_LOG ?= 1
HEADLESS   ?= true

DEBUG            ?= 1
LIBGUESTFS_DEBUG ?= $(DEBUG)
GUESTFISH        := guestfish
VIRT_SYSPREP     := virt-sysprep
VIRT_SPARSIFY    := virt-sparsify
QEMU_IMG         := qemu-img

define CLOUD_CONFIG
#cloud-config
password: ubuntu
ssh_pwauth: true
chpasswd:
  expire: false
endef

define PACKERFILE
source "qemu" "$(NAME)" {
  accelerator = "kvm"

  disk_image   = true
  iso_url      = "https://cloud-images.ubuntu.com/releases/$(RELEASE)/$(ARTIFACT)"
  iso_checksum = "$(CHECKSUM)"

  memory    = "$(MEMORY)"
  disk_size = "$(DISK_SIZE)"

  qemuargs = [
    ["-cdrom", "$(SELF)/.cache/$(ARTIFACT).iso"],
    ["-serial", "stdio"],
  ]

  ssh_username = "ubuntu"
  ssh_password = "ubuntu"

  output_directory = "$(SELF)/.cache/output/"
  vm_name          = "packer-$(NAME).qcow2"

  headless = $(HEADLESS)
}
build {
  sources = ["source.qemu.$(NAME)"]
  provisioner "shell" {
    execute_command = "sudo -iu root {{.Vars}} bash {{.Path}}"
    scripts = [
      "remote-exec/01-basics.sh",
    ]
  }
}
endef

export

.PHONY: all

all: build

$(SELF)/.cache/cloud-config.yml:
	mkdir -p $(SELF)/.cache/ && echo "$$CLOUD_CONFIG" >$@

$(SELF)/.cache/$(ARTIFACT).iso: $(SELF)/.cache/cloud-config.yml
	cloud-localds $@ $^

.PHONY: build

build: $(SELF)/.cache/output/packer-$(NAME).qcow2 $(SELF)/Makefile

$(SELF)/.cache/output/packer-$(NAME).qcow2: $(SELF)/.cache/$(ARTIFACT).iso $(wildcard $(SELF)/remote-exec/*.sh)
	if ! [[ -e $(SELF)/.cache/build.pkr.hcl ]]; then ln -s /dev/stdin $(SELF)/.cache/build.pkr.hcl; fi
	$(PACKER) build -force $(SELF)/.cache/build.pkr.hcl <<< "$$PACKERFILE"

.PHONY: post-process

post-process: SRC_DIR = $(SELF)/post-process
post-process: DST_DIR = /opt/post-process
post-process: SRC_SCRIPTS = $(sort $(wildcard $(SRC_DIR)/*.sh))
post-process: DST_SCRIPTS = $(SRC_SCRIPTS:$(SRC_DIR)/%.sh=$(DST_DIR)/%.sh)
post-process: $(SELF)/.cache/output/packer-$(NAME).qcow2 $(SRC_SCRIPTS) $(SELF)/Makefile
	# run guestfish post-processing
	$(GUESTFISH) --add $< --inspector echo $@ \
	: copy-in $(SRC_DIR) $(dir $(DST_DIR)) \
	: glob chmod 0755 $(DST_DIR)/* \
	$(foreach item,$(DST_SCRIPTS),: command '$(item)') \
	: rm-rf $(DST_DIR)
	# reset / "sysprep" the image
	$(VIRT_SYSPREP) --add $< \
	--selinux-relabel \
	--root-password disabled \
	--hostname localhost.localdomain \
	--run-command 'truncate -s0 -c /etc/machine-id' \
	--delete /etc/resolv.conf
	# decrease image size
	$(VIRT_SPARSIFY) --in-place $<
	$(QEMU_IMG) convert -c -O qcow2 $< $(SELF)/.cache/$(NAME).qcow2

.PHONY: clean

clean:
	-rm -rf $(SELF)/.cache/
