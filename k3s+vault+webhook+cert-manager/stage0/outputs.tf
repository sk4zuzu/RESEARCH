output "kubeconfig" {
  value = var.kubeconfig
}

output "vault" {
  value = {
    namespace = kubernetes_namespace.vault.metadata[0].name
    name      = "vault"
    token     = "root"
    address   = "http://${join(":", [
      data.kubernetes_service.vault.spec[0].cluster_ip,
      data.kubernetes_service.vault.spec[0].port[0].port,
    ])}"
  }
}

output "certmanager" {
  value = {
    namespace = kubernetes_namespace.certmanager.metadata[0].name
    name      = "certmanager"
  }
}
