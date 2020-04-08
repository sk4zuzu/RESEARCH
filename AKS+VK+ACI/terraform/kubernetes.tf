
resource "kubernetes_deployment" "kubernetes-helloworld" {
  count = var.enable_provisioning ? 1 : 0

  depends_on = [ helm_release.helm-virtual-kubelet ]

  metadata {
    name = "helloworld"
    labels = {
      test = "helloworld"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        test = "helloworld"
      }
    }

    template {
      metadata {
        labels = {
          test = "helloworld"
        }
      }

      spec {
        container {
          name = "helloworld"

          image             = "microsoft/aci-helloworld"
          image_pull_policy = "Always"

          resources {
            requests {
              memory = 16
              cpu    = 1
            }
          }

          port {
            name           = "http"
            protocol       = "TCP"
            container_port = 80
          }

          port {
            name           = "https"
            container_port = 443
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

# vim:ts=2:sw=2:et:syn=terraform:
