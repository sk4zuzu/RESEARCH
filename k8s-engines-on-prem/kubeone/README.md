## 1. TEST ENVIRONMENTS

- [6-node on-prem libvirt/KVM cluster based on Ubuntu Server cloud image 18.04](https://github.com/sk4zuzu/vm-pool/blob/5753fcf35976439f108b9e7bbecbe886bd24fbaa/LIVE/u1/terragrunt.hcl#L25-L39)

- [6-node on-prem libvirt/KVM cluster based on Centos 7 cloud image](https://github.com/sk4zuzu/vm-pool/blob/5753fcf35976439f108b9e7bbecbe886bd24fbaa/LIVE/c1/terragrunt.hcl#L25-L39)

- [6-node Azure VM cluster based on Ubuntu Server 18.04](https://github.com/sk4zuzu/RESEARCH/tree/master/k8s-engines-on-prem/azure-ubuntu)

## 2. DESIGN

- installed from a single statically-linked binary
- uses kubeadm, the "classic" experience
- installs all required system packages automatically (including docker-ce)
- executes bash snippets via ssh

```
NAME                  STATUS   ROLES    AGE     VERSION
node/u1a1.ubuntu.lh   Ready    master   2m58s   v1.18.12
node/u1a2.ubuntu.lh   Ready    master   2m19s   v1.18.12
node/u1a3.ubuntu.lh   Ready    master   84s     v1.18.12
node/u1b1.ubuntu.lh   Ready    <none>   64s     v1.18.12
node/u1b2.ubuntu.lh   Ready    <none>   57s     v1.18.12
node/u1b3.ubuntu.lh   Ready    <none>   64s     v1.18.12

NAMESPACE     NAME                                              READY   STATUS    RESTARTS   AGE
kube-system   pod/calico-kube-controllers-5cc64575d9-rhrn7      1/1     Running   0          77s
kube-system   pod/canal-8gpsd                                   2/2     Running   0          78s
kube-system   pod/canal-d4lqz                                   2/2     Running   0          64s
kube-system   pod/canal-k944p                                   2/2     Running   0          78s
kube-system   pod/canal-tfkh8                                   2/2     Running   0          78s
kube-system   pod/canal-vnd9b                                   2/2     Running   0          64s
kube-system   pod/canal-w4bwm                                   2/2     Running   0          57s
kube-system   pod/coredns-d6d746d5d-9d4kn                       1/1     Running   0          2m40s
kube-system   pod/coredns-d6d746d5d-wrcbz                       1/1     Running   0          2m40s
kube-system   pod/etcd-u1a1.ubuntu.lh                           1/1     Running   0          2m49s
kube-system   pod/etcd-u1a2.ubuntu.lh                           1/1     Running   0          2m7s
kube-system   pod/etcd-u1a3.ubuntu.lh                           0/1     Pending   0          1s
kube-system   pod/kube-apiserver-u1a1.ubuntu.lh                 1/1     Running   0          2m49s
kube-system   pod/kube-apiserver-u1a2.ubuntu.lh                 1/1     Running   0          2m7s
kube-system   pod/kube-apiserver-u1a3.ubuntu.lh                 1/1     Running   0          24s
kube-system   pod/kube-controller-manager-u1a1.ubuntu.lh        1/1     Running   1          2m49s
kube-system   pod/kube-controller-manager-u1a2.ubuntu.lh        1/1     Running   0          2m7s
kube-system   pod/kube-proxy-dk9k8                              1/1     Running   0          2m19s
kube-system   pod/kube-proxy-dnkx5                              1/1     Running   0          64s
kube-system   pod/kube-proxy-q4h7x                              1/1     Running   0          57s
kube-system   pod/kube-proxy-s2wzx                              1/1     Running   0          84s
kube-system   pod/kube-proxy-vddsl                              1/1     Running   0          64s
kube-system   pod/kube-proxy-vnhlm                              1/1     Running   0          2m40s
kube-system   pod/kube-scheduler-u1a1.ubuntu.lh                 1/1     Running   1          2m48s
kube-system   pod/kube-scheduler-u1a2.ubuntu.lh                 1/1     Running   0          2m7s
kube-system   pod/kube-scheduler-u1a3.ubuntu.lh                 1/1     Running   0          8s
kube-system   pod/machine-controller-7bfb85845-n4f5g            1/1     Running   0          56s
kube-system   pod/machine-controller-webhook-7bf5f89954-47qp7   1/1     Running   0          56s
kube-system   pod/metrics-server-5f75c7cb4f-gj4rq               1/1     Running   0          81s
kube-system   pod/node-local-dns-54vxf                          1/1     Running   0          64s
kube-system   pod/node-local-dns-7h5m8                          1/1     Running   0          64s
kube-system   pod/node-local-dns-7tsvf                          1/1     Running   0          82s
kube-system   pod/node-local-dns-c58zf                          1/1     Running   0          82s
kube-system   pod/node-local-dns-dvnbb                          1/1     Running   0          57s
kube-system   pod/node-local-dns-vsjpb                          1/1     Running   0          82s
```

## 3. OFFLINE / AIR-GAPPED

- not fully supported / automated (but provides at least a script to download docker images)
- user needs to provide on-prem docker-registry like [here](https://github.com/sk4zuzu/RESEARCH/blob/master/k8s-engines-on-prem/kubeone/docker-compose.yml#L16-L24)

## 4. CNI PLUGINS

supported:
- canal (default)
- weave

calico is only supported via "addon" [here](https://github.com/kubermatic/kubeone/pull/972/commits/9e89b3786836fe19f89f237757ea4a9363e6707c)

## 5. RESULTS

- [asciinema casts](https://github.com/sk4zuzu/RESEARCH/tree/master/k8s-engines-on-prem/kubeone/docs)

### 5.1 UBUNTU

- v1.18.12 installed with no errors in `11m1.982s`
- upgraded with no errors to v1.19.4 in `10m49.110s`

### 5.2 CENTOS

- v1.18.12 installed with no errors in `13m42.656s`
- upgraded with no errors to v1.19.4 in `10m28.346s`

### 5.3 AZURE UBUNTU (ONLINE)

- v1.18.12 failed repeatedly (no data)
- nothing to upgrade (no data)

## 6. PROS / CONS

PROS:
- installed using single statically-linked binary
- supports recent Kubernetes versions
- uses generally-available docker images
- installs system packages automatically
- provides script for pulling and pushing docker images to local docker-registry (although it uses docker instead of skopeo)
- extracts kubeconfig automatically
- seems stable enough for on-prem usage

CONS:
- bad hard-to-read / no-examples documentation (I had to read source code to understand how to configure on-prem cluster [here](https://github.com/kubermatic/kubeone/blob/v1.1.0/pkg/cmd/config.go))
- installs system packages
- poor cni support
- looks like a "ssh-engine" to run bash scripts
