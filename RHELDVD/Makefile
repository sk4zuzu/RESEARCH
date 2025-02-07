SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

MACHINE ?= virt

export

.PHONY: all clean run

all: run

clean:
	-pkill -f qemu-system-aarch64
	rm -f $(SELF)/*.fd
	rm -f $(SELF)/*.img
	cp -f $(SELF)/rhel9-original.qcow2 $(SELF)/rhel9.qcow2

run: $(SELF)/flash0.img $(SELF)/flash1.img
	qemu-system-aarch64 \
	-nographic \
	-machine $(MACHINE),gic-version=max \
	-m 2048M \
	-cpu max \
	-smp 4 \
	-netdev user,id=vnet,hostfwd=:127.0.0.1:0-:22 \
	-device virtio-net-pci,netdev=vnet \
	-drive file=$(SELF)/rhel9.qcow2,if=none,id=drive0,cache=writeback \
	-device virtio-blk,drive=drive0,bootindex=0 \
	-drive file=$(SELF)/flash0.img,format=raw,if=pflash \
	-drive file=$(SELF)/flash1.img,format=raw,if=pflash

$(SELF)/flash0.img: $(SELF)/DEBUGAARCH64_QEMU_EFI.fd
	dd if=/dev/zero of=$@ bs=1M count=64
	dd if=$(SELF)/DEBUGAARCH64_QEMU_EFI.fd of=$@ conv=notrunc

$(SELF)/flash1.img:
	dd if=/dev/zero of=$@ bs=1M count=64

$(SELF)/DEBUGAARCH64_QEMU_EFI.fd:
	curl -fsSL -o $@ https://retrage.github.io/edk2-nightly/bin/$(notdir $@)
