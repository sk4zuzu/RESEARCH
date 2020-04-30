
SELF := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

NAME      ?= kubelo
TIMESTAMP ?= $(shell date +'%Y%m%d-%H%M%S-%s')

PACKER_LOG ?= 1

include $(SELF)/../Makefile.ENV

define PACKERFILE
{
  "builders": [
    {
      "type": "amazon-ebs",

      "access_key": "$(ACCESS_KEY)",
      "secret_key": "$(SECRET_KEY)",

      "region": "$(REGION)",
      "instance_type": "t2.micro",

      "source_ami_filter": {
        "filters": {
          "virtualization-type": "hvm",
          "name": "ubuntu/images/*ubuntu-bionic-18.04-amd64-server-*",
          "root-device-type": "ebs"
        },
        "owners": ["099720109477"],
        "most_recent": true
      },

      "ssh_username": "ubuntu",
      "ami_name": "$(NAME)-$(TIMESTAMP)"
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
	packer build -force - <<< "$$PACKERFILE"

# vim:ts=4:sw=4:noet:syn=make:
