resource "kubernetes_namespace" "consul" {
  metadata {
    name = "consul"
  }
}

resource "argocd_application" "consul" {
  metadata {
    namespace = local.stage0.argocd.namespace
    name      = "consul"
  }
  wait = false
  spec {
    project = "default"
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = kubernetes_namespace.consul.metadata[0].name
    }
    source {
      repo_url        = "https://helm.releases.hashicorp.com"
      chart           = "consul"
      target_revision = "0.33.0"
      helm {
        values = yamlencode({
          connectInject = {
            enabled = true
          }
          controller = {
            enabled = true
          }
          server = {
            replicas = 1
          }
        })
      }
    }
    sync_policy {
      automated = {
        prune       = true
        self_heal   = false
        allow_empty = true
      }
    }
  }
}
