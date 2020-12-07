SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

SKOPEO_VERSION    = v1.2.0
KUBESPRAY_VERSION = v2.14.2

SSH_OPTIONS := -o ForwardAgent=yes \
               -o StrictHostKeyChecking=no \
               -o GlobalKnownHostsFile=/dev/null \
               -o UserKnownHostsFile=/dev/null

define RUN_LOCAL_DOWNLOAD
docker run --rm \
--net=host \
-e SSH_AUTH_SOCK=/.agent \
-v $$SSH_AUTH_SOCK:/.agent \
-v /var/run/docker.sock:/var/run/docker.sock \
-v $(SELF)/inventory/:/kubespray/inventory/ \
-v $(SELF)/files/kubespray_cache/:/tmp/kubespray_cache/ \
-it quay.io/kubespray/kubespray:$(KUBESPRAY_VERSION) \
ansible-playbook -vv \
-i inventory/$(1)/hosts.ini \
--limit 'etcd[0],kube-master[0],kube-node[0]' \
-b \
-e kube_version='$(2)' \
-e download_localhost='{{ true }}' \
-e download_run_once='{{ true }}' \
--tags container-engine,download \
cluster.yml
endef

define RUN_LOCAL
docker run --rm \
--net=host \
-e SSH_AUTH_SOCK=/.agent \
-v $$SSH_AUTH_SOCK:/.agent \
-v $(SELF)/inventory/:/kubespray/inventory/ \
-it quay.io/kubespray/kubespray:$(KUBESPRAY_VERSION) \
ansible-playbook -vv \
-i inventory/$(1)/hosts.ini \
-b \
-e kube_version='$(2)' \
-e docker_insecure_registries='{{ ["10.8.102.4:5000"] }}' \
-e gcr_image_repo='10.8.102.4:5000' \
-e kube_image_repo='10.8.102.4:5000' \
-e docker_image_repo='10.8.102.4:5000' \
-e quay_image_repo='10.8.102.4:5000' \
-e kubelet_download_url='http://10.8.102.2/kubelet-{{ kube_version }}-{{ image_arch }}' \
-e kubectl_download_url='http://10.8.102.2/kubectl-{{ kube_version }}-{{ image_arch }}' \
-e kubeadm_download_url='http://10.8.102.2/kubeadm-{{ kubeadm_version }}-{{ image_arch }}' \
-e cni_download_url='http://10.8.102.2/cni-plugins-linux-{{ image_arch }}-{{ cni_version }}.tgz' \
-e calicoctl_download_url='http://10.8.102.2/calicoctl' \
$(3)
endef

define RUN_LOCAL_CLUSTER
$(call RUN_LOCAL,$(1),$(2),cluster.yml)
endef

define RUN_LOCAL_UPGRADE
$(call RUN_LOCAL,$(1),$(2),upgrade-cluster.yml)
endef

define RUN_REMOTE
docker run --rm \
--net=host \
-e SSH_AUTH_SOCK=/.agent \
-v $$SSH_AUTH_SOCK:/.agent \
-v $(SELF)/inventory/:/kubespray/inventory/ \
-it quay.io/kubespray/kubespray:$(KUBESPRAY_VERSION) \
ansible-playbook -vv \
-i inventory/$(1)/hosts.ini \
-b \
-e kube_version='$(2)' \
$(3)
endef

define RUN_REMOTE_CLUSTER
$(call RUN_REMOTE,$(1),$(2),cluster.yml)
endef

define RUN_REMOTE_UPGRADE
$(call RUN_REMOTE,$(1),$(2),upgrade-cluster.yml)
endef

.PHONY: all prereq-u1 prereq-c1

all:

prereq-u1: $(SELF)/files/skopeo
	ansible-playbook -v -i $(SELF)/u1.ini prereq.yml

prereq-c1: $(SELF)/files/skopeo
	ansible-playbook -v -i $(SELF)/c1.ini prereq.yml

$(SELF)/files/skopeo:
	curl -fsSL -o $@ https://github.com/alvistack/containers-skopeo/releases/download/$(SKOPEO_VERSION)/skopeo-$(SKOPEO_VERSION)-linux-amd64
	chmod +x $@

.PHONY: r1download-u1 r1download-c1 r1 r1purge r1logs

r1download-u1: prereq-u1
	cd $(SELF)/ && $(call RUN_LOCAL_DOWNLOAD,u1,v1.17.13)
	cd $(SELF)/ && $(call RUN_LOCAL_DOWNLOAD,u1,v1.18.10)

r1download-c1: prereq-c1
	cd $(SELF)/ && $(call RUN_LOCAL_DOWNLOAD,c1,v1.17.13)
	cd $(SELF)/ && $(call RUN_LOCAL_DOWNLOAD,c1,v1.18.10)

r1:
	cd $(SELF)/ && docker-compose up --detach && docker-compose logs --follow

r1purge:
	cd $(SELF)/ && docker-compose down --volumes

r1logs:
	cd $(SELF)/ && docker-compose logs --follow

.PHONY: u1 u1upgrade

u1:
	cd $(SELF)/ && $(call RUN_LOCAL_CLUSTER,u1,v1.17.13)
	cd $(SELF)/ && ssh -q $(SSH_OPTIONS) ubuntu@10.50.2.10 sudo cat /etc/kubernetes/admin.conf >$(SELF)/kubeconfig-u1.yml

u1upgrade:
	cd $(SELF)/ && $(call RUN_LOCAL_UPGRADE,u1,v1.18.10)
	cd $(SELF)/ && ssh -q $(SSH_OPTIONS) ubuntu@10.50.2.10 sudo cat /etc/kubernetes/admin.conf >$(SELF)/kubeconfig-u1.yml

.PHONY: c1 c1upgrade

c1:
	cd $(SELF)/ && $(call RUN_LOCAL_CLUSTER,c1,v1.17.13)
	cd $(SELF)/ && ssh -q $(SSH_OPTIONS) centos@10.20.2.10 sudo cat /etc/kubernetes/admin.conf >$(SELF)/kubeconfig-c1.yml

c1upgrade:
	cd $(SELF)/ && $(call RUN_LOCAL_UPGRADE,c1,v1.18.10)
	cd $(SELF)/ && ssh -q $(SSH_OPTIONS) centos@10.20.2.10 sudo cat /etc/kubernetes/admin.conf >$(SELF)/kubeconfig-c1.yml

.PHONY: au1 au1upgrade

au1:
	cd $(SELF)/ && $(call RUN_REMOTE_CLUSTER,au1,v1.17.13)

au1upgrade:
	cd $(SELF)/ && $(call RUN_REMOTE_UPGRADE,au1,v1.18.10)
