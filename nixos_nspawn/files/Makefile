SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

RELEASE_focal := release-20220511
TARBALL_focal := ubuntu-20.04-minimal-cloudimg-amd64-root.tar.xz

COMMON_APT := apt-transport-https bash bridge-utils curl file gawk git gnupg2 groff htop ifupdown iproute2 iptables iputils-ping jq libxml2-utils mc neovim net-tools openssh-client openssh-server ripgrep ruby sudo systemd-container uuid-runtime wget

define SSH_CONFIG
StrictHostKeyChecking no
UserKnownHostsFile /dev/null
ForwardAgent yes
endef

define AUTHORIZED_KEYS
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDML2lXp1XovPkwdNf1kNCoZDx2OxAMre6B4TifrAioS6wFDkCiUCmuVS9bIO4vZTMxz1AomLkH0LgJI30GMGtStySTEQPtjqTrjLCfJXj3hiPnjQJbNHZmB/nbjBYMmtmAqgLFTDomHxj9d+oBx6O+xtpVGj8c/NfVan/XkQa0dwGAOCQuxJWPlaXdyWRQblEHzbtlJB5VPCEOvUI+0gJ/kBCATKvwqMO3hqA7MuAKNETqFLpU7qSdD7ZPa7J2M90J8ceI3gIMHE+7fEWudMzkac+TW832YkEGgNitLYt0STN3d33TGy7b9GXuIrUlqfL3VuR4rrtx4Siesfhfz5lUbz9BwTgsKT+XNqF6+BJJD87hPSb6tl2hChiJnUay7QhKGF/FHEkjqljS//Eg7HqD6nat29yLqXu38sY1UbLyWTZSEV/Uujjkby+6lb7ZrLXM62pQC0Zx2ZWeCnOkzrxkQXDd16wFngiB8k4JO6MADu2F6IvwIRUqg9xOj3o56w3dcMuyvnjRaaxBhLF5XtSFfVePqvjfM0qYPfbU3VIjrSd42lfuM0N2fhljjDCa6vf2q2nqkakHWp8mEE4aISeMgQoAlTYfDVM10ICoPgF1ZAHS+5BIR0cPAzwoPxrMm0sj56/t5M4O2R9XmGqrbdnWANsoXW76LJ3wMStnEXpWaQ== mopala@opennebula.io
endef

define HOSTS
127.0.0.1    localhost
::1          localhost ip6-localhost ip6-loopback
ff02::1      ip6-allnodes
ff02::2      ip6-allrouters
10.2.11.30 sigma
10.2.11.40 delta services storage
10.2.11.50 epsilon
10.2.11.60 omicron
endef

define RC_LOCAL
#!/usr/bin/env bash
set -o errexit
[[ -e /dev/mem ]] || { mknod -m 660 /dev/mem c 1 1 && chown root:kmem /dev/mem; }
for (( k = 0; k < 8; k++ )); do
    [[ -e /dev/nbd$$(( k )) ]] || mknod -m 660 /dev/nbd$$(( k )) b 43 $$(( k * 32 ))
done
for (( k = 0; k < 8; k++ )); do
    [[ -e /dev/loop$$(( k )) ]] || mknod -m 660 /dev/loop$$(( k )) b 7 $$(( k ))
done
endef

define RC_LOCAL_OVERRIDE_CONF
[Install]
WantedBy=multi-user.target
endef

define render_interfaces
auto lo
iface lo inet loopback
iface host0 inet manual
auto eth1
iface eth1 inet manual
auto br0
iface br0 inet static
    bridge_ports host0
    address 10.2.11.$(1)/24
    gateway 10.2.11.1
auto tap0
iface tap0 inet manual
    pre-up ip tuntap add tap0 mode tap user root
    up ip link set dev tap0 up
    post-down ip link delete dev tap0
endef

define bootstrap_ubuntu_chroot
export DEBIAN_FRONTEND=noninteractive; \
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -; \
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg; \
apt-get -y update; \
apt-get -y install $(1); \
apt-get -y purge unattended-upgrades; \
apt-get -y clean; \
ssh-keygen -A;
endef

define bootstrap_ubuntu
curl -fsSLo $(SELF)/$(2)-$(RELEASE_$(2)).tar.xz -C- https://cloud-images.ubuntu.com/minimal/releases/$(2)/$(RELEASE_$(2))/$(TARBALL_$(2))
install -d $(1) && tar -xf $(SELF)/$(2)-$(RELEASE_$(2)).tar.xz -C $(1)
echo "deb mirror://mirrors.ubuntu.com/mirrors.txt $(2)              main restricted universe"  >$(1)/etc/apt/sources.list
echo "deb mirror://mirrors.ubuntu.com/mirrors.txt $(2)-updates      main restricted"          >>$(1)/etc/apt/sources.list
echo "deb http://archive.ubuntu.com/ubuntu        $(2)              main restricted universe" >>$(1)/etc/apt/sources.list
echo "deb http://archive.ubuntu.com/ubuntu        $(2)-updates      main restricted"          >>$(1)/etc/apt/sources.list
echo "deb http://security.ubuntu.com/ubuntu       $(2)-security     main restricted universe" >>$(1)/etc/apt/sources.list
echo "deb https://apt.releases.hashicorp.com      $(2)              main"                     >>$(1)/etc/apt/sources.list
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] \
          https://apt.kubernetes.io               kubernetes-xenial main"                     >>$(1)/etc/apt/sources.list
install -D /dev/fd/0 $(1)/run/systemd/resolve/stub-resolv.conf <<< "nameserver 1.1.1.1"
mount -t proc proc $(1)/proc/
chroot $(1)/ /bin/env -i bash --noprofile --norc -ec "$(call bootstrap_ubuntu_chroot,$(3))"
-umount $(1)/proc/
endef

define configure_ubuntu
if ! grep "^ubuntu:" $(2)/etc/group; then echo "ubuntu:x:1000:" >>$(2)/etc/group; fi
if ! grep "^ubuntu:" $(2)/etc/passwd; then echo "ubuntu:x:1000:1000::/home/ubuntu:/bin/bash" >>$(2)/etc/passwd; fi
if ! grep "^ubuntu:" $(2)/etc/shadow; then echo "ubuntu:!:1::::::" >>$(2)/etc/shadow; fi
echo "ubuntu ALL=(ALL:ALL) NOPASSWD:SETENV: ALL" >$</etc/sudoers.d/ubuntu
install -o 1000 -g 1000 -m u=rwx,go= -d $(2)/home/ubuntu/{,.ssh/,.kube/}
install -o 1000 -g 1000 -m u=rw,go= /dev/fd/0 $(2)/home/ubuntu/.ssh/config          <<< "$$SSH_CONFIG"
install -o 1000 -g 1000 -m u=rw,go= /dev/fd/0 $(2)/home/ubuntu/.ssh/authorized_keys <<< "$$AUTHORIZED_KEYS"
install -o 0 -g 0 -m u=rwx,go= -d $(2)/root/{.ssh/,.kube/}
install -o 0 -g 0 -m u=rw,go= /dev/fd/0 $(2)/root/.ssh/config          <<< "$$SSH_CONFIG"
install -o 0 -g 0 -m u=rw,go= /dev/fd/0 $(2)/root/.ssh/authorized_keys <<< "$$AUTHORIZED_KEYS"
if ! grep "^DNS=" $(2)/etc/systemd/resolved.conf; then echo "DNS=1.1.1.1" >>$(2)/etc/systemd/resolved.conf; fi
echo "$$INTERFACES" >$(2)/etc/network/interfaces
echo "$$HOSTS" >$(2)/etc/hosts
echo "$(1)" >$(2)/etc/hostname
echo >$(2)/etc/systemd/network/80-container-host0.network
install -o 0 -g 0 -m u=rwx,go=r /dev/fd/0 $(2)/etc/rc.local <<< "$$RC_LOCAL"
install -o 0 -g 0 -m u=rwx,go=rx -d $(2)/etc/systemd/system/rc-local.service.d/
echo "$$RC_LOCAL_OVERRIDE_CONF" >$(2)/etc/systemd/system/rc-local.service.d/override.conf
ln -sf /lib/systemd/system/rc-local.service $(2)/etc/systemd/system/multi-user.target.wants/rc-local.service
endef

export

.PHONY: all ls list switch start-all stop-all purge-all

all: sigma delta epsilon omicron

ls list:
	@machinectl list

switch:
	@nixos-rebuild switch

start-all: start-sigma start-delta start-epsilon start-omicron

stop-all: stop-sigma stop-delta stop-epsilon stop-omicron

purge-all: purge-sigma purge-delta purge-epsilon purge-omicron

.PHONY: archive-all unarchive-all

archive-all: archive-sigma archive-delta archive-epsilon archive-omicron

unarchive-all: unarchive-sigma unarchive-delta unarchive-epsilon unarchive-omicron

.PHONY: sigma start-sigma stop-sigma purge-sigma

sigma: INTERFACES = $(call render_interfaces,30)
sigma: $(SELF)/sigma/
	$(call configure_ubuntu,$@,$<)

$(SELF)/sigma/:
	$(call bootstrap_ubuntu,$@,focal,$(COMMON_APT) cloud-utils gcc kubectl libguestfs0 libguestfs-tools linux-image-generic make nodejs packer ruby-bundler ruby-dev s3cmd tmux yarnpkg)

start-sigma:
	-machinectl start sigma

stop-sigma:
	-machinectl stop sigma

purge-sigma:
	-umount $(SELF)/sigma/proc/
	-chattr -i $(SELF)/sigma/etc/resolv.conf
	-rm -rf $(SELF)/sigma/

.PHONY: archive-sigma unarchive-sigma

archive-sigma: $(SELF)/sigma/
	tar -czpf $(SELF)/sigma.tar.gz sigma/

unarchive-sigma: $(SELF)/sigma.tar.gz
	tar -xzpf $< -C $(SELF)/

.PHONY: delta start-delta stop-delta purge-delta

delta: INTERFACES = $(call render_interfaces,40)
delta: $(SELF)/delta/
	$(call configure_ubuntu,$@,$<)

$(SELF)/delta/:
	$(call bootstrap_ubuntu,$@,focal,$(COMMON_APT) augeas-lenses augeas-tools libaugeas-dev python3-pip python3-virtualenv)

start-delta:
	machinectl start delta

stop-delta:
	-machinectl stop delta

purge-delta:
	-umount $(SELF)/delta/proc/
	-chattr -i $(SELF)/delta/etc/resolv.conf
	-rm -rf $(SELF)/delta/

.PHONY: archive-delta unarchive-delta

archive-delta: $(SELF)/delta/
	tar -czpf $(SELF)/delta.tar.gz delta/

unarchive-delta: $(SELF)/delta.tar.gz
	tar -xzpf $< -C $(SELF)/

.PHONY: epsilon start-epsilon stop-epsilon purge-epsilon

epsilon: INTERFACES = $(call render_interfaces,50)
epsilon: $(SELF)/epsilon/
	$(call configure_ubuntu,$@,$<)

$(SELF)/epsilon/:
	$(call bootstrap_ubuntu,$@,focal,$(COMMON_APT) augeas-lenses augeas-tools libaugeas-dev python3-pip ruby)

start-epsilon:
	machinectl start epsilon

stop-epsilon:
	-machinectl stop epsilon

purge-epsilon:
	-umount $(SELF)/epsilon/proc/
	-chattr -i $(SELF)/epsilon/etc/resolv.conf
	-rm -rf $(SELF)/epsilon/

.PHONY: archive-epsilon unarchive-epsilon

archive-epsilon: $(SELF)/epsilon/
	tar -czpf $(SELF)/epsilon.tar.gz epsilon/

unarchive-epsilon: $(SELF)/epsilon.tar.gz
	tar -xzpf $< -C $(SELF)/

.PHONY: omicron start-omicron stop-omicron purge-omicron

omicron: INTERFACES = $(call render_interfaces,60)
omicron: $(SELF)/omicron/
	$(call configure_ubuntu,$@,$<)

$(SELF)/omicron/:
	$(call bootstrap_ubuntu,$@,focal,$(COMMON_APT) augeas-lenses augeas-tools libaugeas-dev python3-pip ruby)

start-omicron:
	machinectl start omicron

stop-omicron:
	-machinectl stop omicron

purge-omicron:
	-umount $(SELF)/omicron/proc/
	-chattr -i $(SELF)/omicron/etc/resolv.conf
	-rm -rf $(SELF)/omicron/

.PHONY: archive-omicron unarchive-omicron

archive-omicron: $(SELF)/omicron/
	tar -czpf $(SELF)/omicron.tar.gz omicron/

unarchive-omicron: $(SELF)/omicron.tar.gz
	tar -xzpf $< -C $(SELF)/
