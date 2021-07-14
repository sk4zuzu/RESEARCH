resource "kubernetes_namespace" "eck" {
  metadata {
    name = "eck"
  }
}

resource "argocd_application" "eck" {
  metadata {
    namespace = local.stage0.argocd.namespace
    name      = "eck-operator"
  }
  wait = true
  spec {
    project = "default"
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = kubernetes_namespace.eck.metadata[0].name
    }
    source {
      repo_url        = "https://helm.elastic.co/"
      chart           = "eck-operator"
      target_revision = "1.6.0"
    }
    sync_policy {
      automated = {
        prune       = true
        self_heal   = true
        allow_empty = true
      }
    }
  }
}
