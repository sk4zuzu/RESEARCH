
SELF := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

DESTINATION_DIR  ?= $(SELF)
DESTINATION_FILE ?= $(DESTINATION_DIR)/urandom.dd
CHECKSUM_FILE    ?= $(DESTINATION_FILE).sha1

MIB_COUNT     ?= 1024
INLINE_SCRIPT := dd if=/dev/urandom bs=1M count=$(MIB_COUNT) oflag=dsync status=none

export

.PHONY: all

all: case1

.PHONY: case1

case1:
	install -d $(DESTINATION_DIR)/
	set -o errexit -o nounset -o pipefail \
	&& FIFO_PATH=`mktemp -ud $$PWD/fifo-XXXXXX` \
	&& mkfifo $$FIFO_PATH \
	&& trap "rm -f $$FIFO_PATH" EXIT \
	&& $$INLINE_SCRIPT \
	| tee $$FIFO_PATH 1>$(DESTINATION_FILE) \
	| dd if=$$FIFO_PATH oflag=dsync status=none \
	| sha1sum >&2
	sha1sum $(DESTINATION_FILE)

.PHONY: case2

case2:
	@install -d $(DESTINATION_DIR)/
	@set -o errexit -o nounset -o pipefail \
	&& FIFO_PATH=`mktemp -ud $$PWD/fifo-XXXXXX` \
	&& mkfifo $$FIFO_PATH \
	&& trap "rm -f $$FIFO_PATH" EXIT \
	&& ($$INLINE_SCRIPT | tee $$FIFO_PATH & sha1sum $$FIFO_PATH >&2 & wait)

# vim:ts=4:sw=4:noet:syn=make:
