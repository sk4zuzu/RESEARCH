
resource "helm_release" "helm-virtual-kubelet" {
  name = "virtual-kubelet"

  chart = "https://github.com/virtual-kubelet/virtual-kubelet/raw/master/charts/virtual-kubelet-latest.tgz"

  set {
    name  = "provider"
    value = "azure"
  }

  set {
    name  = "providers.azure.targetAKS"
    value = true
  }

  set {
    name  = "providers.azure.vnet.enabled"
    value = true
  }

  set {
    name  = "providers.azure.vnet.subnetName"
    value = azurerm_subnet.vnet-aci.name
  }

  set {
    name  = "providers.azure.vent.subnetCidr"
    value = azurerm_subnet.vnet-aci.address_prefix
  }

  set {
    name  = "providers.azure.vnet.clusterCidr"
    value = azurerm_subnet.vnet-aks.address_prefix
  }

  set {
    name  = "providers.azure.vnet.kubeDnsIp"
    value = cidrhost(var.vnet_address_space, 10)
  }

  set {
    name  = "providers.azure.masterUri"
    value = azurerm_kubernetes_cluster.aks.kube_config.0.host
  }
}

# vim:ts=2:sw=2:et:syn=terraform:
