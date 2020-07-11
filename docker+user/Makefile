
SELF := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

HOST_UID := $(shell id -u)
HOST_GID := $(shell id -g)

define BUILD_AND_RUN
.PHONY: $(1)
$(1): $(SELF)/$(1).Dockerfile
	docker build -t research_docker_user_$$@ \
	    --build-arg HOST_UID=$(HOST_UID) \
	    --build-arg HOST_GID=$(HOST_GID) \
	    - < $$<
	docker run --rm -t research_docker_user_$$@
endef

export

.PHONY: all

all: debian alpine

$(eval \
	$(call BUILD_AND_RUN,debian))

$(eval \
	$(call BUILD_AND_RUN,alpine))

# vim:ts=4:sw=4:noet:syn=make:
