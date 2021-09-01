output "apps" {
  value = {
    consul = argocd_application.consul
  }
}

output "consul" {
  value = {
    namespace = kubernetes_namespace.consul.metadata[0].name
    name      = "consul"
  }
}
