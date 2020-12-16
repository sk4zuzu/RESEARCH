M_ALL_NAMESPACES = kaasbal1 kaasbal2 kaasbal3

define NAMESPACE
---
apiVersion: v1
kind: Namespace
metadata:
  name: $(1)
  labels:
    name: $(1)
endef

.PHONY: all

all:
	@: $(file >./namespaces.yml) $(foreach ns,$(M_ALL_NAMESPACES),$(file >>./namespaces.yml,$(call NAMESPACE,$(ns))))
