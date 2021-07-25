output "loki" {
  value = {
    namespace = kubernetes_namespace.loki.metadata[0].name
  }
}
