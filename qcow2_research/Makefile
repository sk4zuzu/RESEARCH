SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

NBDX ?= 15

export

.PHONY: all

all: $(SELF)/commit/4.qcow2 $(SELF)/convert/4.qcow2

$(SELF)/source/1.qcow2:
	install -d $(SELF)/nbd$(NBDX)/ $(dir $@)
	qemu-img create -f qcow2 $@ 1G
	qemu-nbd --connect /dev/nbd$(NBDX) $@
	mkfs.ext4 /dev/nbd$(NBDX)
	mount /dev/nbd$(NBDX) $(SELF)/nbd$(NBDX)/
	echo 1 > $(SELF)/nbd$(NBDX)/1
	sync
	umount $(SELF)/nbd$(NBDX)/
	qemu-nbd --disconnect /dev/nbd$(NBDX)

$(SELF)/source/2.qcow2: $(SELF)/source/1.qcow2
	install -d $(SELF)/nbd$(NBDX)/ $(dir $@)
	qemu-img create -f qcow2 $@ -F qcow2 -b $(notdir $<)
	qemu-nbd --connect=/dev/nbd$(NBDX) $@
	mount /dev/nbd$(NBDX) $(SELF)/nbd$(NBDX)/
	echo 2 > $(SELF)/nbd$(NBDX)/2
	sync
	umount $(SELF)/nbd$(NBDX)/
	qemu-nbd --disconnect /dev/nbd$(NBDX)

$(SELF)/source/3.qcow2: $(SELF)/source/2.qcow2
	install -d $(SELF)/nbd$(NBDX)/ $(dir $@)
	qemu-img create -f qcow2 $@ -F qcow2 -b $(notdir $<)
	qemu-nbd --connect=/dev/nbd$(NBDX) $@
	mount /dev/nbd$(NBDX) $(SELF)/nbd$(NBDX)/
	echo 3 > $(SELF)/nbd$(NBDX)/3
	sync
	umount $(SELF)/nbd$(NBDX)/
	qemu-nbd --disconnect /dev/nbd$(NBDX)

$(SELF)/source/4.qcow2: $(SELF)/source/3.qcow2
	install -d $(SELF)/nbd$(NBDX)/ $(dir $@)
	qemu-img create -f qcow2 $@ -F qcow2 -b $(notdir $<)
	qemu-nbd --connect=/dev/nbd$(NBDX) $@
	mount /dev/nbd$(NBDX) $(SELF)/nbd$(NBDX)/
	echo 4 > $(SELF)/nbd$(NBDX)/4
	sync
	umount $(SELF)/nbd$(NBDX)/
	qemu-nbd --disconnect /dev/nbd$(NBDX)

$(SELF)/commit/0.qcow2: $(SELF)/source/1.qcow2 $(SELF)/source/2.qcow2 $(SELF)/source/3.qcow2
	install -d $(SELF)/nbd$(NBDX)/ $(SELF)/commit/
	cp $^ $(SELF)/commit/
	cp $< $@ && qemu-img rebase -f qcow2 $(subst source,commit,$(word 2,$^)) -F qcow2 -b $@
	echo $(subst source,commit,$^) | xargs -r -n1 | sort -r | head -n-1 | while read IMG; do \
		echo $$IMG; \
		qemu-img commit -f qcow2 $$IMG; \
	done

$(SELF)/commit/4.qcow2: $(SELF)/source/4.qcow2 $(SELF)/commit/0.qcow2
	cp $< $@
	qemu-img rebase -f qcow2 $@ -F qcow2 -b $(lastword $^)

$(SELF)/convert/0.qcow2: $(SELF)/source/1.qcow2 $(SELF)/source/2.qcow2 $(SELF)/source/3.qcow2
	install -d $(SELF)/nbd$(NBDX)/ $(SELF)/convert/
	cp $^ $(SELF)/convert/
	qemu-img convert -c -O qcow2 $(lastword $^) $@

$(SELF)/convert/4.qcow2: $(SELF)/source/4.qcow2 $(SELF)/convert/0.qcow2
	cp $< $@
	qemu-img rebase -f qcow2 $@ -F qcow2 -b $(lastword $^)

.PHONY: info

info: $(SELF)/source/4.qcow2 $(SELF)/commit/4.qcow2 $(SELF)/convert/4.qcow2
	for IMG in $^; do \
		echo; \
		qemu-img info $$IMG; \
		qemu-nbd --connect=/dev/nbd$(NBDX) $$IMG; \
		mount /dev/nbd$(NBDX) $(SELF)/nbd$(NBDX)/; \
		ls -lha $(SELF)/nbd$(NBDX)/; \
		umount $(SELF)/nbd$(NBDX)/; \
		qemu-nbd --disconnect /dev/nbd$(NBDX); \
	done

.PHONY: clean

clean:
	-qemu-nbd --disconnect /dev/nbd$(NBDX)
	-rmdir $(SELF)/nbd$(NBDX)/
	rm -rf $(SELF)/{source,commit,convert}/
