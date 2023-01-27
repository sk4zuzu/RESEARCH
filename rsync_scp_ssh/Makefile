SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

SSH_OPTS := -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
SSH_PORT := 2222

export

.PHONY: all clean

all:

clean:
	rm -rf $(SELF)/dst/

rsync%:
	install -d $(SELF)/dst/
	cd $(SELF)/src/$*/ && rsync -e 'ssh $(SSH_OPTS) -p $(SSH_PORT)' -LRaz --delete \
		. localhost:$(SELF)/dst/
	@find $(SELF)/dst/ -type f

scp%:
	install -d $(SELF)/dst/
	cd $(SELF)/src/$*/ && scp -rp $(SSH_OPTS) -P $(SSH_PORT) \
		. localhost:$(SELF)/dst/
	@find $(SELF)/dst/ -type f

ssh%:
	install -d $(SELF)/dst/
	set -o pipefail; \
	tar -czpf- -C $(SELF)/src/$*/ . \
		| ssh $(SSH_OPTS) -p $(SSH_PORT) localhost tar -xzpf- --recursive-unlink -C $(SELF)/dst/
	@find $(SELF)/dst/ -type f

rsync_subset%:
	install -d $(SELF)/dst/
	cd $(SELF)/src/$*/ && rsync -e 'ssh $(SSH_OPTS) -p $(SSH_PORT)' -LRaz --delete \
		a/a c/c localhost:$(SELF)/dst/
	@find $(SELF)/dst/ -type f

# This cannot really be done, due to scp limitation.
#scp_subset%:
#	install -d $(SELF)/dst/
#	cd $(SELF)/src/$*/ && scp -rp $(SSH_OPTS) -P $(SSH_PORT) \
#		a/a c/c localhost:$(SELF)/dst/
#	@find $(SELF)/dst/ -type f

ssh_subset%:
	install -d $(SELF)/dst/
	set -o pipefail; \
	tar -czpf- -C $(SELF)/src/$*/ a/a c/c \
		| ssh $(SSH_OPTS) -p $(SSH_PORT) localhost tar -xzpf- --recursive-unlink -C $(SELF)/dst/
	@find $(SELF)/dst/ -type f
