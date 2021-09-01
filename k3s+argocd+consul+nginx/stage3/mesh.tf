resource "argocd_application" "mesh" {
  metadata {
    namespace = local.stage0.argocd.namespace
    name      = "mesh"
  }
  wait = false
  spec {
    source {
      repo_url        = "https://github.com/sk4zuzu/RESEARCH.git"
      path            = "k3s+argocd+consul+nginx/stage3/mesh"
      target_revision = "argocd"
    }
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = local.stage1.consul.namespace
    }
    sync_policy {
      automated = {
        prune       = true
        self_heal   = false
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
