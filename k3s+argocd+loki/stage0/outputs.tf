output "kubeconfig" {
  value = var.kubeconfig
}

output "argocd" {
  value = {
    namespace = kubernetes_namespace.argocd.metadata[0].name
    name      = "argocd"
    user      = "admin"
    pass      = data.kubernetes_secret.argocd.data.password
    address = "http://${join(":", [
      data.kubernetes_service.argocd.spec[0].cluster_ip,
      data.kubernetes_service.argocd.spec[0].port[0].port,
    ])}"
  }
}
