SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

ALPINE_VER_LONG  ?= 3.14.2
ALPINE_VER_SHORT ?= 3.14
ALPINE_VER_ARCH  ?= x86_64

HEADLESS ?= true

KC := kubectl
VC := $(SELF)/../bin/virtctl

export

.PHONY: all

all: alpine-build alpine-upload

.PHONY: alpine-build

alpine-build: $(SELF)/output_alpine-$(ALPINE_VER_LONG)-$(ALPINE_VER_ARCH)/alpine-$(ALPINE_VER_LONG)-$(ALPINE_VER_ARCH).qcow2

$(SELF)/output_alpine-$(ALPINE_VER_LONG)-$(ALPINE_VER_ARCH)/alpine-$(ALPINE_VER_LONG)-$(ALPINE_VER_ARCH).qcow2: $(SELF)/k3s-alpine.pkr.hcl
	rm -rf $(dir $@)
	packer build $<

.PHONY: alpine-upload

alpine-upload: SVC_CDI_UPLOADPROXY_IPV4 = $(shell $(KC) --kubeconfig $(HOME)/.kube/k3s.yaml --namespace cdi get svc/cdi-uploadproxy -o jsonpath='{.spec.clusterIP}')
alpine-upload: $(SELF)/output_alpine-$(ALPINE_VER_LONG)-$(ALPINE_VER_ARCH)/alpine-$(ALPINE_VER_LONG)-$(ALPINE_VER_ARCH).qcow2
	$(VC) \
	--kubeconfig $(HOME)/.kube/k3s.yaml \
	--namespace cdi \
	image-upload dv alpine-nocloud \
	--size 8Gi \
	--image-path $< \
	--uploadproxy-url https://$$SVC_CDI_UPLOADPROXY_IPV4 \
	--insecure || true # FIXME
