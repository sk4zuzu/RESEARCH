resource "kubernetes_namespace" "nginx" {
  metadata {
    name = "nginx"
  }
}

resource "kubernetes_pod" "nginx" {
  metadata {
    namespace = kubernetes_namespace.nginx.metadata[0].name
    name      = "nginx"
    annotations = {
      "nomad.hashicorp.com/datacenters" = "dc1"
    }
  }
  spec {
    node_selector = {
      "kubernetes.io/role"    = "agent"
      "beta.kubernetes.io/os" = "linux"
      "type"                  = "virtual-kubelet"
    }
    toleration {
      key      = "virtual-kubelet.io/provider"
      operator = "Exists"
    }
    toleration {
      key    = "hashicorp.com/nomad"
      effect = "NoSchedule"
    }
    dns_policy = "ClusterFirst"
    container {
      name              = "nginx"
      image             = "nginx:alpine"
      image_pull_policy = "Always"
      port {
        container_port = 80
      }
    }
  }
}
