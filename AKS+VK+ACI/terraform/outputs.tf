
output "kubeconfig" {
  value = azurerm_kubernetes_cluster.aks.kube_config_raw
}

# vim:ts=2:sw=2:et:syn=terraform:
