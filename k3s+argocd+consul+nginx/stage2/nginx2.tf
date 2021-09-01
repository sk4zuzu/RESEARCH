resource "argocd_application" "nginx2" {
  metadata {
    namespace = local.stage0.argocd.namespace
    name      = "nginx2"
  }
  wait = false
  spec {
    source {
      repo_url        = "https://github.com/sk4zuzu/RESEARCH.git"
      path            = "k3s+argocd+consul+nginx/stage2/nginx2"
      target_revision = "argocd"
    }
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = kubernetes_namespace.nginx.metadata[0].name
    }
    sync_policy {
      automated = {
        prune       = true
        self_heal   = true
        allow_empty = true
      }
      retry {
        limit = "5"
        backoff = {
          duration     = "30s"
          max_duration = "2m"
          factor       = "2"
        }
      }
    }
  }
}
