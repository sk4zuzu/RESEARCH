## 1. TEST ENVIRONMENTS

- [6-node on-prem libvirt/KVM cluster based on Ubuntu Server cloud image 18.04](https://github.com/sk4zuzu/vm-pool/blob/5753fcf35976439f108b9e7bbecbe886bd24fbaa/LIVE/u1/terragrunt.hcl#L25-L39)

- [6-node on-prem libvirt/KVM cluster based on Centos 7 cloud image](https://github.com/sk4zuzu/vm-pool/blob/5753fcf35976439f108b9e7bbecbe886bd24fbaa/LIVE/c1/terragrunt.hcl#L25-L39)

- [6-node Azure VM cluster based on Ubuntu Server 18.04](https://github.com/sk4zuzu/RESEARCH/tree/master/k8s-engines-on-prem/azure-ubuntu)

## 2. DESIGN

- can be managed using pre-built docker images form [quay.io](https://quay.io/repository/kubespray/kubespray)
- ansible based
- uses kubeadm, the "classic" experience
- installs all required system packages automatically (including docker-ce)

```
NAME        STATUS   ROLES    AGE     VERSION
node/u1a1   Ready    master   3m15s   v1.17.13
node/u1a2   Ready    master   2m44s   v1.17.13
node/u1a3   Ready    master   2m44s   v1.17.13
node/u1b1   Ready    <none>   108s    v1.17.13
node/u1b2   Ready    <none>   108s    v1.17.13
node/u1b3   Ready    <none>   108s    v1.17.13

NAMESPACE     NAME                                             READY   STATUS    RESTARTS   AGE
kube-system   pod/calico-kube-controllers-74b9b94cfc-2mghd     1/1     Running   0          67s
kube-system   pod/calico-node-96rw7                            1/1     Running   1          88s
kube-system   pod/calico-node-gctfv                            1/1     Running   1          88s
kube-system   pod/calico-node-hl95t                            1/1     Running   1          88s
kube-system   pod/calico-node-m9kks                            1/1     Running   1          88s
kube-system   pod/calico-node-qn98z                            1/1     Running   1          88s
kube-system   pod/calico-node-x9864                            1/1     Running   1          88s
kube-system   pod/coredns-58b9c97c99-7qgnm                     1/1     Running   0          55s
kube-system   pod/coredns-58b9c97c99-9fx4m                     1/1     Running   0          51s
kube-system   pod/dns-autoscaler-77c78db666-w2kgx              1/1     Running   0          52s
kube-system   pod/kube-apiserver-u1a1                          1/1     Running   0          3m8s
kube-system   pod/kube-apiserver-u1a2                          1/1     Running   0          2m37s
kube-system   pod/kube-apiserver-u1a3                          1/1     Running   0          2m37s
kube-system   pod/kube-controller-manager-u1a1                 1/1     Running   0          3m8s
kube-system   pod/kube-controller-manager-u1a2                 1/1     Running   0          2m37s
kube-system   pod/kube-controller-manager-u1a3                 1/1     Running   0          2m37s
kube-system   pod/kube-proxy-2xxjh                             1/1     Running   0          108s
kube-system   pod/kube-proxy-4rps2                             1/1     Running   0          2m44s
kube-system   pod/kube-proxy-7zxbz                             1/1     Running   0          2m56s
kube-system   pod/kube-proxy-h2xmz                             1/1     Running   0          108s
kube-system   pod/kube-proxy-hm7lm                             1/1     Running   0          108s
kube-system   pod/kube-proxy-jsxl6                             1/1     Running   0          2m44s
kube-system   pod/kube-scheduler-u1a1                          1/1     Running   0          3m8s
kube-system   pod/kube-scheduler-u1a2                          1/1     Running   0          2m37s
kube-system   pod/kube-scheduler-u1a3                          1/1     Running   0          2m37s
kube-system   pod/kubernetes-dashboard-84bfd98759-hsrjk        1/1     Running   0          50s
kube-system   pod/kubernetes-metrics-scraper-79745547b-8g58c   1/1     Running   0          50s
kube-system   pod/nginx-proxy-u1b1                             1/1     Running   0          107s
kube-system   pod/nginx-proxy-u1b2                             1/1     Running   0          107s
kube-system   pod/nginx-proxy-u1b3                             1/1     Running   0          107s
kube-system   pod/nodelocaldns-4rdr7                           1/1     Running   0          51s
kube-system   pod/nodelocaldns-fmb5b                           1/1     Running   0          51s
kube-system   pod/nodelocaldns-kjx77                           1/1     Running   0          51s
kube-system   pod/nodelocaldns-lr4cf                           1/1     Running   0          51s
kube-system   pod/nodelocaldns-pvlwc                           1/1     Running   0          51s
kube-system   pod/nodelocaldns-tjwfr                           1/1     Running   0          51s
```

## 3. OFFLINE / AIR-GAPPED

- not fully supported / automated
- docker images and binary files (kubeadm, kubectl, ...) can be downloaded automatically like [here](https://github.com/sk4zuzu/RESEARCH/blob/master/k8s-engines-on-prem/kubespray/Makefile#L12-L30)
- the "download procedure" requires exising 2-node online cluster (sic!)
- the "download procedure" fails if there is no "/etc/kubernetes/" folder present on the machines (sic!)
- user needs to provide on-prem docker-registry and http server like [here](https://github.com/sk4zuzu/RESEARCH/blob/master/k8s-engines-on-prem/kubespray/docker-compose.yml#L16-L34)
- it's possible to use (automatically set) on-prem mirror repository for system packages (that completes the offline installation)

## 4. CNI PLUGINS

supported:
- calico (default)
- canal
- cilium
- flannel
- kube-ovn
- kube-router
- macvlan
- ovn4nfv
- weave

## 5. RESULTS

- [asciinema casts](https://github.com/sk4zuzu/RESEARCH/tree/master/k8s-engines-on-prem/kubespray/docs)

### 5.1 UBUNTU

- v1.17.13 installed with no errors in `13m1.466s`
- upgrade to v1.18.10 failed repeatedly (no data)

### 5.2 CENTOS

- v1.17.13 installed with no errors in `13m16.955s`
- upgraded with no errors to v1.18.10 in `11m6.016s`

### 5.3 AZURE UBUNTU (ONLINE)

- v1.17.13 installed with no errors in `61m55.709s`
- upgraded with no errors to v1.18.10 in `59m58.529s`

## 6. PROS / CONS

PROS:
- extended list of supported CNI plugins
- uses generally-available docker images
- installs system packages automatically

CONS:
- latest release (2.14.2) does not support recent Kubernetes versions
- insane procedure for downloading docker images and files (requires a running online cluster!)
- no script for building docker registry automatically
- docker socket and full sudo privileges on the controller machine are required to run some of the ansible plays (sic!)
- installs system packages
- very slow
- upgrades are not completely stable
- bad documentation (I needed couple of hours of reading ansible code to understand what is going on)
- does not extract kubeconfig automatically
