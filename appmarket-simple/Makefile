SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

CMD ?=

define BUILD_AND_RUN
.PHONY: $(1)

$(1): $(SELF)/$(1).Dockerfile
	podman build -t appmarket-simple-$$@ -f $$<
	podman run --rm -p 9292:9292 -it appmarket-simple-$$@ $(CMD)
endef

export

.PHONY: all

all:

$(eval \
	$(call BUILD_AND_RUN,ubuntu2004))

$(eval \
	$(call BUILD_AND_RUN,ubuntu2204))

$(eval \
	$(call BUILD_AND_RUN,alma8))
