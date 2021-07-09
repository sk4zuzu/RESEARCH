resource "argocd_repository" "git" {
  for_each = {
    "RESEARCH" = {
      repo = "https://github.com/sk4zuzu/RESEARCH.git"
    }
  }
  type = "git"
  repo = each.value.repo
}

resource "kubernetes_namespace" "argocd" {
  for_each = toset([
    "elasticsearch",
    "fluentd",
    "kibana",
  ])
  metadata {
    name = each.key
  }
}

resource "argocd_application" "argocd" {
  metadata {
    namespace = local.stage0.argocd.namespace
    name      = "argocd"
  }
  wait = false
  spec {
    project = "default"
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = local.stage0.argocd.namespace
    }
    source {
      repo_url        = argocd_repository.git["RESEARCH"].repo
      path            = "k3s+argocd+elasticsearch+fluentd+kibana/stage1/argocd"
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
