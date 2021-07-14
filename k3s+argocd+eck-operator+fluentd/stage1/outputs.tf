output "eck" {
  value = {
    namespace = kubernetes_namespace.eck.metadata[0].name
  }
}
