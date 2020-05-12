
SELF := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

MIB_COUNT ?= 1024

DESTINATION_DIR  ?= $(SELF)
DESTINATION_FILE ?= $(DESTINATION_DIR)/urandom.dd
CHECKSUM_FILE    ?= $(DESTINATION_FILE).sha1
FIFO_PATH        ?= $(DESTINATION_DIR)/fifo

export

.PHONY: all

all:
	install -d $(DESTINATION_DIR)/
	set -o errexit -o nounset -o pipefail \
	&& mkfifo $(FIFO_PATH) \
	&& trap "rm -f $(FIFO_PATH)" EXIT \
	&& dd if=/dev/urandom bs=1M count=$(MIB_COUNT) oflag=dsync status=none \
	| tee $(FIFO_PATH) 1>$(DESTINATION_FILE) \
	| dd if=$(FIFO_PATH) oflag=dsync status=none \
	| sha1sum >&2
	sha1sum $(DESTINATION_FILE)

# vim:ts=4:sw=4:noet:syn=make:
