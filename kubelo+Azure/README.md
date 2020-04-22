
Based on [virtual-kubelet/azure-aci](https://github.com/virtual-kubelet/azure-aci/blob/master/README.md).

1. Use Linux.
2. Create `Makefile.ENV` from `Makefile.ENV.sample` and provide proper values.
3. Run `make binaries` to install all dependencies.
4. Run `az login` and authenticate to Azure.
5. Run `make storage` to create state bucket for terraform.
6. Run `make apply-env1` to deploy `AKS`, `virtual-kubelet` and some test containers.
7. You may encounter `eventual consistency errors`, if so, then try re-applying.
8. Examine your Azure console.
9. Run `make destroy-env1` to cleanup.

[//]: # ( vim:set ts=2 sw=2 et syn=markdown: )
