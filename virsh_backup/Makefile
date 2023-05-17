SHELL := $(shell which bash)
SUDO  := $(shell which sudo) -E
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

SSH_OPTS := \
-o StrictHostKeyChecking=no \
-o UserKnownHostsFile=/dev/null \
-o IdentitiesOnly=yes \
-i $(SELF)/.cache/id_rsa

VIRSH    := $(SUDO) virsh
QEMU_IO  := $(SUDO) qemu-io
QEMU_IMG := $(SUDO) qemu-img
QEMU_NBD := $(SUDO) qemu-nbd
NBDINFO  := $(SUDO) nbdinfo

NAME   ?= asd
TARGET ?= vda

PACKER_VERSION := 1.8.6

define HASHICORP_RELEASE_INSTALL =
$(SELF)/bin/$(1): $(SELF)/bin/$(1)-$(2)
	rm -f $$@ && ln -s $$< $$@
$(SELF)/bin/$(1)-$(2):
	install -d /tmp/$(1)-$(2)/ \
	&& curl -fSL https://releases.hashicorp.com/$(1)/$(2)/$(1)_$(2)_linux_amd64.zip \
	        -o /tmp/$(1)-$(2)/download.zip \
	&& unzip -o -d /tmp/$(1)-$(2)/ /tmp/$(1)-$(2)/download.zip \
	&& mv /tmp/$(1)-$(2)/$(1)* $$@ \
	&& rm -rf /tmp/$(1)-$(2)/ \
	&& chmod +x $$@
endef

RELEASE  := 3.17
VERSION  := $(RELEASE).3
ARTIFACT := alpine-virt-$(VERSION)-x86_64.iso
CHECKSUM := 3ae1f6304346ce99e5eafddf0132c86c0fc7136ffad767a2c725501d8a9d5c04

PACKER     := $(SELF)/bin/packer
PACKER_LOG ?= 1

define PACKERFILE =
source "qemu" "$(NAME)" {
  accelerator = "kvm"

  disk_image   = false
  iso_url      = "https://dl-cdn.alpinelinux.org/alpine/v$(RELEASE)/releases/x86_64/$(ARTIFACT)"
  iso_checksum = "$(CHECKSUM)"

  memory    = "1024"
  disk_size = "10240"

  net_device     = "virtio-net"
  disk_interface = "virtio"

  qemuargs = [
    ["-serial", "stdio"],
  ]

  ssh_username     = "root"
  ssh_password     = "asd"
  shutdown_command = "/sbin/poweroff"

  output_directory = "$(SELF)/.cache/output/"
  vm_name          = "packer-$(NAME).qcow2"

  headless = true

  http_directory = "$(SELF)/remote-exec/"

  boot_wait = "10s"
  boot_command = [
    "root<enter><wait1s>",
    "ifconfig eth0 up && udhcpc -i eth0<enter>",
    "wget -qO- http://{{.HTTPIP}}:{{.HTTPPort}}/00-bootstrap.sh | ash<enter>",
  ]
}
build {
  sources = ["source.qemu.$(NAME)"]
  provisioner "shell" {
    execute_command = "bash --login {{.Path}}"
    scripts = [
      "remote-exec/01-basics.sh",
      "remote-exec/50-setup.sh",
    ]
  }
}
endef

define META_DATA_YML =
instance-id: $(NAME)
local-hostname: $(NAME)
endef

define USER_DATA_YML =
#cloud-config
ssh_pwauth: false
disable_root: false
users:
- name: root
  lock_passwd: false
  ssh_authorized_keys: ['$(1)']
endef

define NETWORK_CONFIG_YML =
version: 2
ethernets:
  eth0:
    addresses: ['192.168.122.86']
    dhcp4: false
    dhcp6: false
    gateway4: '192.168.122.1'
    macaddress: '52:54:52:54:52:54'
    nameservers:
      addresses: ['1.1.1.1']
endef

define DOMAIN_XML =
<domain type="kvm">
  <qemu:capabilities>
    <qemu:add capability="incremental-backup"/>
  </qemu:capabilities>
  <name>$(NAME)</name>
  <memory unit="KiB">131072</memory>
  <vcpu placement="static">2</vcpu>
  <resource>
    <partition>/machine</partition>
  </resource>
  <os>
    <type arch="x86_64" machine="pc">hvm</type>
    <boot dev="hd"/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
  <cpu mode="host-passthrough" check="none" migratable="on"/>
  <clock offset="utc"/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <devices>
    <interface type="network">
      <mac address="52:54:52:54:52:54"/>
      <source network="default" bridge="virbr0"/>
      <target dev="vnet0"/>
      <model type="virtio"/>
      <alias name="net0"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x05" function="0x0"/>
    </interface>
    <disk type="file" device="disk">
      <driver name="qemu" type="qcow2"/>
      <source file="$(SELF)/.cache/base.qcow2"/>
      <target dev="$(TARGET)" bus="virtio"/>
      <alias name="virtio-disk0"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x07" function="0x0"/>
    </disk>
    <disk type="file" device="cdrom">
      <driver name="qemu" type="raw"/>
      <source file="$(SELF)/.cache/cloud-config.iso" index="1"/>
      <backingStore/>
      <target dev="hdd" bus="ide"/>
      <readonly/>
      <serial>cloudinit</serial>
      <alias name="ide0-1-1"/>
      <address type="drive" controller="0" bus="1" target="0" unit="1"/>
    </disk>
    <controller type="pci" index="0" model="pci-root">
      <alias name="pci.0"/>
    </controller>
    <controller type="ide" index="0">
      <alias name="ide"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x01" function="0x1"/>
    </controller>
    <controller type="virtio-serial" index="0">
      <alias name="virtio-serial0"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x06" function="0x0"/>
    </controller>
    <serial type="pty">
      <source path="/dev/pts/1"/>
      <target type="isa-serial" port="0">
        <model name="isa-serial"/>
      </target>
      <alias name="serial0"/>
    </serial>
    <console type="pty" tty="/dev/pts/1">
      <source path="/dev/pts/1"/>
      <target type="serial" port="0"/>
      <alias name="serial0"/>
    </console>
    <console type="pty">
      <source path="/dev/pts/2"/>
      <target type="virtio" port="1"/>
      <alias name="console1"/>
    </console>
    <input type="mouse" bus="ps2">
      <alias name="input0"/>
    </input>
    <input type="keyboard" bus="ps2">
      <alias name="input1"/>
    </input>
    <graphics type="spice" port="5900" autoport="yes" listen="0.0.0.0">
      <listen type="address" address="0.0.0.0"/>
    </graphics>
    <audio id="1" type="spice"/>
    <video>
      <model type="cirrus" vram="16384" heads="1" primary="yes"/>
      <alias name="video0"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x0"/>
    </video>
    <memballoon model="virtio">
      <alias name="balloon0"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x08" function="0x0"/>
    </memballoon>
    <rng model="virtio">
      <backend model="random">/dev/urandom</backend>
      <alias name="rng0"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x09" function="0x0"/>
    </rng>
  </devices>
  <seclabel type="dynamic" model="dac" relabel="yes">
    <label>+0:+0</label>
    <imagelabel>+0:+0</imagelabel>
  </seclabel>
</domain>
endef

define CHECKPOINT_XML =
<domaincheckpoint>
  <disks>
    <disk name="$(TARGET)" checkpoint="bitmap"/>
    <disk name="hdd" checkpoint="no"/>
  </disks>
</domaincheckpoint>
endef

define BACKUP_XML =
<domainbackup mode="pull">
  <incremental>$(2)</incremental>
  <server transport="unix" socket="$(SELF)/.cache/backup$(1).sock"/>
  <disks>
    <disk name="$(TARGET)" backup="yes" type="file">
      <scratch file="$(SELF)/.cache/scratch$(1).qcow2"/>
    </disk>
  </disks>
</domainbackup>
endef

export

.PHONY: all

all:

.PHONY: requirements keys modules packages

requirements: keys modules packages $(SELF)/bin/packer

keys: $(SELF)/.cache/id_rsa $(SELF)/.cache/id_rsa.pub

$(SELF)/.cache/id_rsa $(SELF)/.cache/id_rsa.pub &:
	ssh-keygen -t rsa -b 3072 -m PEM -f $@ -N ''

modules:
	$(SUDO) modprobe nbd

packages: PKG := DEBIAN_FRONTEND=noninteractive $(SUDO) apt-get install -y
packages:
	@$(SUDO) apt-get update -y
	@$(PKG) \
		cloud-utils \
		libnbd-bin \
		unzip

$(eval \
	$(call HASHICORP_RELEASE_INSTALL,packer,$(PACKER_VERSION)))

.PHONY: alpine-disk

$(NAME)-disk: $(SELF)/.cache/output/packer-$(NAME).qcow2

$(SELF)/.cache/output/packer-$(NAME).qcow2: $(wildcard $(SELF)/remote-exec/*.sh)
	mkdir -p $(SELF)/.cache/
	if ! [[ -e $(SELF)/.cache/build.pkr.hcl ]]; then ln -s /dev/stdin $(SELF)/.cache/build.pkr.hcl; fi
	$(SUDO) $(PACKER) build -force $(SELF)/.cache/build.pkr.hcl <<< "$$PACKERFILE"
	$(SUDO) chown -R $$UID $(SELF)/.cache/

.PHONY: v virsh ls list

v virsh:
	$(VIRSH)

ls list:
	$(VIRSH) list

.PHONY: create destroy

$(SELF)/.cache/cloud-config.iso: YML1 = $(call META_DATA_YML)
$(SELF)/.cache/cloud-config.iso: YML2 = $(call USER_DATA_YML,$(strip $(file <$(SELF)/.cache/id_rsa.pub)))
$(SELF)/.cache/cloud-config.iso: YML3 = $(call NETWORK_CONFIG_YML)
$(SELF)/.cache/cloud-config.iso:
	install -m u=rw,go= -D /dev/fd/0 $(SELF)/.cache/meta-data.yml <<< "$$YML1"
	install -m u=rw,go= -D /dev/fd/0 $(SELF)/.cache/user-data.yml <<< "$$YML2"
	install -m u=rw,go= -D /dev/fd/0 $(SELF)/.cache/network-config.yml <<< "$$YML3"
	cloud-localds -v $@ \
		$(SELF)/.cache/user-data.yml \
		$(SELF)/.cache/meta-data.yml \
		--network=$(SELF)/.cache/network-config.yml

$(SELF)/.cache/base.qcow2: $(SELF)/.cache/output/packer-$(NAME).qcow2
	cp $< $@

$(SELF)/.cache/domain.xml: XML = $(call DOMAIN_XML)
$(SELF)/.cache/domain.xml:
	install -m u=rw,go= -D /dev/fd/0 $@ <<< "$$XML"

create: $(SELF)/.cache/domain.xml $(SELF)/.cache/cloud-config.iso $(SELF)/.cache/base.qcow2
	$(VIRSH) define $<
	$(VIRSH) start $(NAME)
	for RETRY in 9 8 7 6 5 4 3 2 1 0; do \
		if ssh $(SSH_OPTS) root@192.168.122.86 uname -a; then break; fi; \
		sleep 4; \
	done && [[ "$$RETRY" -gt 0 ]]

destroy:
	-$(VIRSH) destroy $(NAME)
	-$(VIRSH) undefine $(NAME) --snapshots-metadata --checkpoints-metadata

.PHONY: ssh

ssh:
	ssh $(SSH_OPTS) root@192.168.122.86

define FULL =
$(SELF)/.cache/checkpoint$(1).xml: XML = $$(call CHECKPOINT_XML)
$(SELF)/.cache/checkpoint$(1).xml:
	install -m u=rw,go= -D /dev/fd/0 $$@ <<< "$$$$XML"

$(SELF)/.cache/overlay$(1).qcow2: $(SELF)/.cache/checkpoint$(1).xml
	ssh $(SSH_OPTS) root@192.168.122.86 'dd if=/dev/urandom of=/b$(1) bs=1048576 count=100; sync; sha1sum /b[123456789]'
	$(VIRSH) snapshot-create-as $(NAME) --disk-only --atomic --diskspec $(TARGET),file=$$@
	$(VIRSH) checkpoint-create $(NAME) --xmlfile $(SELF)/.cache/checkpoint$(1).xml

$(SELF)/.cache/backup$(1).qcow2: $(SELF)/.cache/base.qcow2
	$(QEMU_IMG) convert -f qcow2 $$< -O qcow2 $$@

.PHONY: b$(1) backup$(1)

b$(1) backup$(1): $(SELF)/.cache/overlay$(1).qcow2 $(SELF)/.cache/backup$(1).qcow2

$(SELF)/.cache/convert$(1).qcow2: $(SELF)/.cache/backup$(1).qcow2
	$(QEMU_IMG) rebase -f qcow2 $$< -F qcow2 -b $(SELF)/.cache/output/packer-$(NAME).qcow2 -u
	$(QEMU_IMG) convert -f qcow2 $$< -O qcow2 $$@
endef

$(eval $(call FULL,1))

define INCREMENTAL =
$(SELF)/.cache/backup$(1).xml: INC = $$(shell $(VIRSH) checkpoint-list $(NAME) --name | head -n-1 | tail -n-1)
$(SELF)/.cache/backup$(1).xml: XML = $$(call BACKUP_XML,$(1),$$(INC))
$(SELF)/.cache/backup$(1).xml:
	install -m u=rw,go= -D /dev/fd/0 $$@ <<< "$$$$XML"

$(SELF)/.cache/backup$(1).qcow2: $(SELF)/.cache/backup$(1).xml
	ssh $(SSH_OPTS) root@192.168.122.86 'dd if=/dev/urandom of=/b$(1) bs=1048576 count=100; sync; sha1sum /b[123456789]'
	$(VIRSH) backup-begin $(NAME) --backupxml $$<
	$(QEMU_IMG) create -f qcow2 -F raw -b 'nbd+unix:///$(TARGET)?socket=$(SELF)/.cache/backup$(1).sock' $$@

$(SELF)/.cache/backup$(1).stdin: $(SELF)/.cache/backup$(1).qcow2
	tee $$@ <<< 'open -C -t none -i native -o driver=qcow2 $$<'
	$(NBDINFO) --map=qemu:dirty-bitmap:backup-$(TARGET) --json 'nbd+unix:///$(TARGET)?socket=$(SELF)/.cache/backup$(1).sock' \
	| jq -r '.[] | select(.description == "dirty") | [.offset, .length] | @tsv' \
	| while read OFFSET LENGTH; do \
		echo read $$$$OFFSET $$$$LENGTH; \
	done \
	| tee -a $$@

$(SELF)/.cache/checkpoint$(1).xml: XML = $$(call CHECKPOINT_XML)
$(SELF)/.cache/checkpoint$(1).xml:
	install -m u=rw,go= -D /dev/fd/0 $$@ <<< "$$$$XML"

.PHONY: b$(1) backup$(1)

b$(1) backup$(1): $(SELF)/.cache/backup$(1).stdin $(SELF)/.cache/checkpoint$(1).xml
	$(QEMU_IO) < $$<
	$(VIRSH) domjobabort $(NAME)
	$(VIRSH) checkpoint-list $(NAME) --name | head -n-1 | tac \
	| while read CHECKPOINT; do \
		$(VIRSH) checkpoint-delete $(NAME) --children $$$$CHECKPOINT; \
	done
	$(VIRSH) checkpoint-create $(NAME) --xmlfile $(SELF)/.cache/checkpoint$(1).xml
endef

$(eval $(call INCREMENTAL,2))
$(eval $(call INCREMENTAL,3))

$(SELF)/.cache/restore1.qcow2: $(SELF)/.cache/backup1.qcow2
	$(QEMU_IMG) convert -f qcow2 $< -O qcow2 $@

$(SELF)/.cache/restore2.qcow2: $(SELF)/.cache/backup2.qcow2
	$(QEMU_IMG) rebase -f qcow2 $< -F qcow2 -b $(SELF)/.cache/backup1.qcow2 -u
	$(QEMU_IMG) convert -f qcow2 $< -O qcow2 $@

$(SELF)/.cache/restore3.qcow2: $(SELF)/.cache/backup3.qcow2
	$(QEMU_IMG) rebase -f qcow2 $< -F qcow2 -b $(SELF)/.cache/backup2.qcow2 -u
	$(QEMU_IMG) rebase -f qcow2 $(SELF)/.cache/backup2.qcow2 -F qcow2 -b $(SELF)/.cache/backup1.qcow2 -u
	$(QEMU_IMG) convert -f qcow2 $< -O qcow2 $@

define PRINT =
.PHONY: p$(1) print$(1)

p$(1) print$(1): $(SELF)/.cache/restore$(1).qcow2
	$(QEMU_NBD) --connect /dev/nbd$(1) $$<
	$(SUDO) install -d $(SELF)/.cache/mnt$(1)/
	$(SUDO) mount /dev/nbd$(1)p3 $(SELF)/.cache/mnt$(1)/
	$(SUDO) ls -lha $(SELF)/.cache/mnt$(1)/
	$(SUDO) sha1sum $(SELF)/.cache/mnt$(1)/b[123456789]
	$(SUDO) umount $(SELF)/.cache/mnt$(1)/
	$(QEMU_NBD) --disconnect /dev/nbd$(1)
	$(SUDO) rm -r $(SELF)/.cache/mnt$(1)/
endef

$(eval $(call PRINT,1))
$(eval $(call PRINT,2))
$(eval $(call PRINT,3))

.PHONY: x clean

x clean: destroy
	-$(SUDO) rm $(SELF)/.cache/*.iso
	-$(SUDO) rm $(SELF)/.cache/*.qcow2
	-$(SUDO) rm $(SELF)/.cache/*.sock
	-$(SUDO) rm $(SELF)/.cache/*.stdin
	-$(SUDO) rm $(SELF)/.cache/*.xml
	-$(SUDO) rm $(SELF)/.cache/*.yml
