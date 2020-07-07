
SELF := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

NAME      ?= kubelo
TIMESTAMP ?= $(shell date +'%Y%m%d-%H%M%S-%s')

RETRIES := 5
DELAY   := 5

PACKER_LOG ?= 1

include $(SELF)/../Makefile.ENV

define PACKERFILE
{
  "builders": [
    {
      "type": "azure-arm",
      "subscription_id": "$(SUBSCRIPTION_ID)",

      "client_id": "$(CLIENT_ID)",
      "client_secret": "$(CLIENT_SECRET)",
      "tenant_id": "$(TENANT_ID)",

      "location": "$(LOCATION)",
      "vm_size": "Standard_B1s",

      "os_type": "Linux",
      "image_publisher": "Canonical",
      "image_offer": "UbuntuServer",
      "image_sku": "18.04-LTS",

      "managed_image_resource_group_name": "$(RESOURCE_GROUP_NAME)",
      "managed_image_name": "$(NAME)-$(TIMESTAMP)"
    }
  ],
  "provisioners": [
    {
      "type": "shell",
      "execute_command": "sudo -iu root {{.Vars}} {{.Path}}",
      "scripts": [
        "remote-exec/01-basics.sh",
        "remote-exec/02-docker.sh",
        "remote-exec/03-kubernetes.sh"
      ]
    }
  ]
}
endef

export

.PHONY: all

all: build

.PHONY: build

build:
	@echo CLIENT_ID=$(CLIENT_ID)
	@echo CLIENT_SECRET=$(CLIENT_SECRET)
	@echo TENANT_ID=$(TENANT_ID)
	sleep 30
	packer build -force - <<< "$$PACKERFILE"

# vim:ts=4:sw=4:noet:syn=make:
