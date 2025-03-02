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
    token_reviewer_jwt = data.external.kubernetes.result.token_reviewer_jwt
  }
}

output "cm" {
  value = {
    namespace = kubernetes_namespace.cm.metadata[0].name
    name      = "cm"
  }
}
