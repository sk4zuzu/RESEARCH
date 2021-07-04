output "kubeconfig" {
  value = var.kubeconfig
}

output "vault" {
  value = {
    namespace = kubernetes_namespace.vault.metadata[0].name
    name      = "vault"
    token     = "root"
    address = "http://${join(":", [
      data.kubernetes_service.vault.spec[0].cluster_ip,
      data.kubernetes_service.vault.spec[0].port[0].port,
    ])}"
    oidc_address = "http://${join(":", [
      data.kubernetes_service.vault.spec[0].cluster_ip,
      8250,
    ])}"
    token_reviewer_jwt = data.external.kubernetes.result.token_reviewer_jwt
  }
}

output "keycloak" {
  value = {
    namespace = kubernetes_namespace.keycloak.metadata[0].name
    name      = "keycloak"
    user      = "admin"
    pass      = "asd"
    address   = "http://${data.kubernetes_service.keycloak.spec[0].cluster_ip}"
  }
}
