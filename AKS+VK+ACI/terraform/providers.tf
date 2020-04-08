
terraform {
  backend "azurerm" {}
}

provider "azuread" {}

provider "azurerm" {
  features {}
}

provider "random" {}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
    load_config_file       = false
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
  }
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
  load_config_file       = false
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
}

# vim:ts=2:sw=2:et:syn=terraform:
