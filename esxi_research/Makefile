SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

export

.PHONY: all requirements \
        binaries ovftool vcsa \
		hypervisor-disks \
		apply destroy \
        clean

all:

requirements: binaries ovftool vcsa

binaries:
	make -f $(SELF)/Makefile.BINARIES

ovftool:
	make -f $(SELF)/Makefile.OVFTOOL

vcsa:
	make -f $(SELF)/Makefile.VCSA

hypervisor-disks:
	cd $(SELF)/packer/esxi/ && make NAME=esxi1
	cd $(SELF)/packer/esxi/ && make NAME=esxi2

apply: hypervisor-disks
	cd $(SELF)/terraform/esxi/ && $(SELF)/bin/terraform init
	cd $(SELF)/terraform/esxi/ && $(SELF)/bin/terraform $@

destroy:
	cd $(SELF)/terraform/esxi/ && $(SELF)/bin/terraform init
	cd $(SELF)/terraform/esxi/ && $(SELF)/bin/terraform $@

clean:
	-make clean -f $(SELF)/Makefile.BINARIES
	-make clean -f $(SELF)/Makefile.OVFTOOL
	-make clean -f $(SELF)/Makefile.VCSA
	-cd $(SELF)/packer/esxi/ && make clean
