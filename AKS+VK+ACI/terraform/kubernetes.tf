
resource "kubernetes_deployment" "kubernetes-cpuhog" {
  count = var.enable_provisioning ? 1 : 0

  depends_on = [ helm_release.helm-virtual-kubelet ]

  metadata {
    name = "cpuhog"
    labels = {
      test = "cpuhog"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        test = "cpuhog"
      }
    }

    template {
      metadata {
        labels = {
          test = "cpuhog"
        }
      }

      spec {
        container {
          name = "cpuhog"

          image             = "sk4zuzu/cpuhog"
          image_pull_policy = "Always"

          resources {
            limits {
              cpu = 0.2
            }
            requests {
              cpu = 0.2
            }
          }

          port {
            name           = "http"
            protocol       = "TCP"
            container_port = 8000
          }
        }

        dns_policy = "ClusterFirst"

        node_selector = {
          "kubernetes.io/role"    = "agent"
          "beta.kubernetes.io/os" = "linux"
          type                    = "virtual-kubelet"
        }

        toleration {
          key      = "virtual-kubelet.io/provider"
          operator = "Exists"
        }

        toleration {
          key    = "azure.com/aci"
          effect = "NoSchedule"
        }
      }
    }
  }
}

resource "kubernetes_service" "kubernetes-cpuhog" {
  count = var.enable_provisioning ? 1 : 0

  depends_on = [ helm_release.helm-virtual-kubelet ]

  metadata {
    name = "cpuhog"
    labels = {
      test = "cpuhog"
    }
  }

  spec {
    type = "ClusterIP"

    selector = {
      test = "cpuhog"
    }

    port {
      port        = 8000
      target_port = 8000
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler" "kubernetes-cpuhog" {
  count = var.enable_provisioning ? 1 : 0

  depends_on = [ helm_release.helm-virtual-kubelet ]

  metadata {
    name = "cpuhog"
    labels = {
      test = "cpuhog"
    }
  }

  spec {
    scale_target_ref {
      kind = "Deployment"
      name = "cpuhog"
    }

    min_replicas = 1
    max_replicas = 4

    target_cpu_utilization_percentage = 50
  }
}

# vim:ts=2:sw=2:et:syn=terraform:
