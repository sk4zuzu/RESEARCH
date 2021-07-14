resource "argocd_repository" "git" {
  for_each = {
    "RESEARCH" = {
      repo = "https://github.com/sk4zuzu/RESEARCH.git"
    }
  }
  type = "git"
  repo = each.value.repo
}

resource "argocd_application" "eck" {
  metadata {
    namespace = local.stage0.argocd.namespace
    name      = "eck"
  }
  wait = true
  spec {
    project = "default"
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = local.stage1.eck.namespace
    }
    source {
      repo_url        = argocd_repository.git["RESEARCH"].repo
      path            = "k3s+argocd+eck-operator+fluentd/stage2/argocd"
      target_revision = "argocd"
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
