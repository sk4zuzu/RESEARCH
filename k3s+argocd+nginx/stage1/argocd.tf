resource "argocd_repository" "git" {
  for_each = {
    "RESEARCH" = {
      repo = "https://github.com/sk4zuzu/RESEARCH.git"
    }
  }
  type = "git"
  repo = each.value.repo
}

resource "kubernetes_namespace" "nginx" {
  metadata {
    name = "nginx"
  }
}

resource "argocd_application" "nginx" {
  metadata {
    namespace = local.stage0.argocd.namespace
    name      = "nginx"
  }
  wait = false
  spec {
    source {
      repo_url        = argocd_repository.git["RESEARCH"].repo
      path            = "k3s+argocd+nginx/stage1/nginx"
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
