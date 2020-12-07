## 1. TEST ENVIRONMENTS

- [6-node on-prem libvirt/KVM cluster based on Ubuntu Server cloud image 18.04](https://github.com/sk4zuzu/vm-pool/blob/5753fcf35976439f108b9e7bbecbe886bd24fbaa/LIVE/u1/terragrunt.hcl#L25-L39)

- [6-node on-prem libvirt/KVM cluster based on Centos 7 cloud image](https://github.com/sk4zuzu/vm-pool/blob/5753fcf35976439f108b9e7bbecbe886bd24fbaa/LIVE/c1/terragrunt.hcl#L25-L39)

- [6-node Azure VM cluster based on Ubuntu Server 18.04](https://github.com/sk4zuzu/RESEARCH/tree/master/k8s-engines-on-prem/azure-ubuntu)

## 2. DESIGN

- installed from a single statically-linked binary
- does not use kubeadm
- requires (only!) docker-ce to be pre-installed on all machines [requirements](https://rancher.com/docs/rke/latest/en/os/)
- uses "hyperkube-style" deployment

```
$ docker ps
CONTAINER ID        IMAGE                                                 COMMAND                  CREATED             STATUS              PORTS               NAMES
a717a88416b8        10.8.101.2:5000/rancher/calico-node                   "start_runit"            4 minutes ago       Up 4 minutes                            k8s_calico-node_calico-node-fm2lx_kube-system_110fc1df-053c-4e07-a6a9-d18b092c7689_0
6203b74014ff        10.8.101.2:5000/rancher/pause:3.1                     "/pause"                 4 minutes ago       Up 4 minutes                            k8s_POD_calico-node-fm2lx_kube-system_110fc1df-053c-4e07-a6a9-d18b092c7689_0
0f9d4b9f38fd        10.8.101.2:5000/rancher/hyperkube:v1.18.12-rancher1   "/opt/rke-tools/entr…"   5 minutes ago       Up 5 minutes                            kube-proxy
bd37f5d76216        10.8.101.2:5000/rancher/hyperkube:v1.18.12-rancher1   "/opt/rke-tools/entr…"   5 minutes ago       Up 5 minutes                            kubelet
81357e60baee        10.8.101.2:5000/rancher/hyperkube:v1.18.12-rancher1   "/opt/rke-tools/entr…"   5 minutes ago       Up 5 minutes                            kube-scheduler
3a0ca597e86c        10.8.101.2:5000/rancher/hyperkube:v1.18.12-rancher1   "/opt/rke-tools/entr…"   5 minutes ago       Up 5 minutes                            kube-controller-manager
abb0328793bf        10.8.101.2:5000/rancher/hyperkube:v1.18.12-rancher1   "/opt/rke-tools/entr…"   5 minutes ago       Up 5 minutes                            kube-apiserver
d6b3de42c623        10.8.101.2:5000/rancher/rke-tools:v0.1.66             "/docker-entrypoint.…"   6 minutes ago       Up 6 minutes                            etcd-rolling-snapshots
923998518d49        10.8.101.2:5000/rancher/coreos-etcd:v3.4.3-rancher1   "/usr/local/bin/etcd…"   6 minutes ago       Up 6 minutes                            etcd
```
```
NAME              STATUS   ROLES               AGE   VERSION
node/10.50.2.10   Ready    controlplane,etcd   68s   v1.18.12
node/10.50.2.11   Ready    controlplane,etcd   68s   v1.18.12
node/10.50.2.12   Ready    controlplane,etcd   68s   v1.18.12
node/10.50.2.20   Ready    worker              67s   v1.18.12
node/10.50.2.21   Ready    worker              67s   v1.18.12
node/10.50.2.22   Ready    worker              67s   v1.18.12

NAMESPACE       NAME                                           READY   STATUS      RESTARTS   AGE
ingress-nginx   pod/default-http-backend-5b564dd459-stjgz      1/1     Running     0          32s
ingress-nginx   pod/nginx-ingress-controller-blz4j             1/1     Running     0          32s
ingress-nginx   pod/nginx-ingress-controller-cj8nd             1/1     Running     0          32s
ingress-nginx   pod/nginx-ingress-controller-fqjdh             1/1     Running     0          32s
kube-system     pod/calico-kube-controllers-6c6fc476f6-82wzb   1/1     Running     0          48s
kube-system     pod/calico-node-7dz2m                          1/1     Running     0          47s
kube-system     pod/calico-node-cm5rc                          0/1     Running     0          47s
kube-system     pod/calico-node-dmwbz                          0/1     Running     0          47s
kube-system     pod/calico-node-kf6zb                          0/1     Running     0          47s
kube-system     pod/calico-node-nczbb                          0/1     Running     0          47s
kube-system     pod/calico-node-zjtmj                          1/1     Running     0          47s
kube-system     pod/coredns-5dd4dfcb45-lvlc4                   1/1     Running     0          10s
kube-system     pod/coredns-5dd4dfcb45-sj44t                   1/1     Running     0          44s
kube-system     pod/coredns-autoscaler-557f965569-4sbdd        1/1     Running     0          43s
kube-system     pod/metrics-server-77956db857-pdklq            1/1     Running     0          38s
kube-system     pod/rke-coredns-addon-deploy-job-2h25s         0/1     Completed   0          46s
kube-system     pod/rke-ingress-controller-deploy-job-9882t    0/1     Completed   0          36s
kube-system     pod/rke-metrics-addon-deploy-job-l47wt         0/1     Completed   0          41s
kube-system     pod/rke-network-plugin-deploy-job-xzrwp        0/1     Completed   0          56s
```
```
# ls -lha /var/lib/rancher/rke/log/
total 36K
drwxr-xr-x 2 root root 4.0K Dec  7 09:39 .
drwxr-xr-x 3 root root 4.0K Dec  7 09:38 ..
lrwxrwxrwx 1 root root  165 Dec  7 09:38 etcd-rolling-snapshots_d6b3de42c623f7011ceae6aa48d7a0ce8c519d37b83461ff9e6c93d755110af5.log -> /var/lib/docker/containers/d6b3de42c623f7011ceae6aa48d7a0ce8c519d37b83461ff9e6c93d755110af5/d6b3de42c623f7011ceae6aa48d7a0ce8c519d37b83461ff9e6c93d755110af5-json.log
lrwxrwxrwx 1 root root  165 Dec  7 09:38 etcd_923998518d4922c1fcff06df9223cd175db07e7ac5201ee9803d967d4b4454b9.log -> /var/lib/docker/containers/923998518d4922c1fcff06df9223cd175db07e7ac5201ee9803d967d4b4454b9/923998518d4922c1fcff06df9223cd175db07e7ac5201ee9803d967d4b4454b9-json.log
lrwxrwxrwx 1 root root  165 Dec  7 09:39 kube-apiserver_abb0328793bfc436910c865251a6d4b48c087fb4a3b7bb41ffdb8c43198cd3e9.log -> /var/lib/docker/containers/abb0328793bfc436910c865251a6d4b48c087fb4a3b7bb41ffdb8c43198cd3e9/abb0328793bfc436910c865251a6d4b48c087fb4a3b7bb41ffdb8c43198cd3e9-json.log
lrwxrwxrwx 1 root root  165 Dec  7 09:39 kube-controller-manager_3a0ca597e86c8a8b53ad46a470d15fa75eee419de429c6017e186f5668c91297.log -> /var/lib/docker/containers/3a0ca597e86c8a8b53ad46a470d15fa75eee419de429c6017e186f5668c91297/3a0ca597e86c8a8b53ad46a470d15fa75eee419de429c6017e186f5668c91297-json.log
lrwxrwxrwx 1 root root  165 Dec  7 09:39 kube-proxy_0f9d4b9f38fd9329b8ffd7ed53c1e09e75ec5ef536f82b98c88fd795cb5cad3b.log -> /var/lib/docker/containers/0f9d4b9f38fd9329b8ffd7ed53c1e09e75ec5ef536f82b98c88fd795cb5cad3b/0f9d4b9f38fd9329b8ffd7ed53c1e09e75ec5ef536f82b98c88fd795cb5cad3b-json.log
lrwxrwxrwx 1 root root  165 Dec  7 09:39 kube-scheduler_81357e60baeeb158097c9945634f231f677ce0252e47e7bdab3cf9b949e43a67.log -> /var/lib/docker/containers/81357e60baeeb158097c9945634f231f677ce0252e47e7bdab3cf9b949e43a67/81357e60baeeb158097c9945634f231f677ce0252e47e7bdab3cf9b949e43a67-json.log
lrwxrwxrwx 1 root root  165 Dec  7 09:39 kubelet_bd37f5d7621626e69d30b1b3532fedaf1cfc87800c658be582ff7cef06e8f4af.log -> /var/lib/docker/containers/bd37f5d7621626e69d30b1b3532fedaf1cfc87800c658be582ff7cef06e8f4af/bd37f5d7621626e69d30b1b3532fedaf1cfc87800c658be582ff7cef06e8f4af-json.log
```

## 3. OFFLINE / AIR-GAPPED

- not fully supported / automated (but easy to implement)
- the list of required docker images can be obtained like so [images](https://github.com/sk4zuzu/RESEARCH/blob/master/k8s-engines-on-prem/rke/Makefile#L10-L11)
- user needs to provide on-prem docker-registry like [here](https://github.com/sk4zuzu/RESEARCH/blob/a8fcf2a6689fe84b5756afc668de1777d0139c23/k8s-engines-on-prem/rke/docker-compose.yml#L16-L24)
- no linux system packages (except for docker-ce with dependencies) are required / installed

## 4. CNI PLUGINS

supported:
- calico
- canal (default)
- flannel
- weave
- [custom plugins](https://rancher.com/docs/rke/latest/en/config-options/add-ons/network-plugins/custom-network-plugin-example/)

## 5. RESULTS

- [asciinema casts](https://github.com/sk4zuzu/RESEARCH/tree/master/k8s-engines-on-prem/rke/docs)

### 5.1 UBUNTU

- docker-ce installed in `4m42.450s`
- v1.18.12 installed with no errors in `3m21.134s`
- upgraded with no errors to v1.19.4 in `5m21.850s`

### 5.2 CENTOS

- docker-ce installed in `5m49.049s`
- v1.18.12 installed with no errors in `3m8.847s`
- upgraded with no errors to v1.19.4 in `4m31.851s`

### 5.3 AZURE UBUNTU (ONLINE)

- docker-ce pre-installed during terraform provisioning (no data)
- v1.18.12 installed with no errors in `12m32.977s`
- upgraded with no errors to v1.19.4 in `16m55.058s`

## 6. PROS / CONS

PROS:
- installed using single statically-linked binary
- supports recent Kubernetes versions
- requires only docker-ce to be pre-installed
- downloading docker images is very simple to implement
- very fast, rke (with pre-installed docker-ce) installs or upgrades in ~5 minutes on 6-node KVM cluster
- very stable, rke did not fail even once during my tests
- cluster configuration file is intuitive and easy to understand
- good / easy-to-read documentation (I did not need to read the source code)
- extracts kubeconfig automatically

CONS:
- no script for downloading docker images and building docker registry automatically
- provides its own docker images
