output "kubeconfig" {
  value = var.kubeconfig
}

output "argocd" {
  value = {
    namespace = "argocd"
    name      = "argocd"
    user      = "admin"
    pass      = nonsensitive(data.kubernetes_secret.argocd.data.password)
    address = "http://${join(":", [
      data.kubernetes_service.argocd.spec[0].cluster_ip,
      data.kubernetes_service.argocd.spec[0].port[0].port,
    ])}"
    ingress = "http://argocd/"
  }
}
