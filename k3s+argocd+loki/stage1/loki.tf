resource "kubernetes_namespace" "loki" {
  metadata {
    name = "loki"
  }
}

resource "argocd_application" "loki" {
  metadata {
    namespace = local.stage0.argocd.namespace
    name      = "loki"
  }
  wait = true
  spec {
    project = "default"
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = kubernetes_namespace.loki.metadata[0].name
    }
    source {
      repo_url        = "https://grafana.github.io/helm-charts"
      chart           = "loki-stack"
      target_revision = "2.4.1"
      helm {
        values = yamlencode({
          grafana = {
            enabled = true
            ingress = {
              enabled = true
              hosts   = ["loki-grafana.loki.svc"]
            }
          }
          prometheus = {
            enabled = true
            alertmanager = {
              enabled = false
            }
            server = {
              enabled = true
            }
          }
        })
      }
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
