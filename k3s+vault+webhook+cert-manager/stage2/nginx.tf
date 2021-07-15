resource "kubernetes_namespace" "nginx" {
  metadata {
    name = "nginx"
  }
}

resource "kubernetes_deployment" "nginx" {
  wait_for_rollout = true
  metadata {
    namespace = kubernetes_namespace.nginx.metadata[0].name
    name      = "nginx"
    labels = {
      app = "nginx"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "nginx"
      }
    }
    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }
      spec {
        container {
          image = "nginx:alpine"
          name  = "nginx"
          env {
            name = "SEC1_AAA"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.secrets["sec1"].metadata[0].name
                key  = "aaa"
              }
            }
          }
          env {
            name = "SEC1_BBB"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.secrets["sec1"].metadata[0].name
                key  = "bbb"
              }
            }
          }
          command = [
            "sh",
            "-c",
            "echo $SEC1_AAA $SEC1_BBB > /usr/share/nginx/html/index.html && exec nginx -g 'daemon off;'",
          ]
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx" {
  metadata {
    namespace = kubernetes_namespace.nginx.metadata[0].name
    name      = "nginx"
  }
  spec {
    selector = {
      app = "nginx"
    }
    type = "ClusterIP"
    port {
      port        = 8080
      target_port = 80
    }
  }
}

resource "kubernetes_ingress" "nginx" {
  wait_for_load_balancer = true
  metadata {
    namespace = kubernetes_namespace.nginx.metadata[0].name
    name      = "nginx"
    annotations = {
      "cert-manager.io/cluster-issuer" = "cluster-issuer"
      "cert-manager.io/common-name"    = "nginx.nginx.svc.cluster.local"
      "cert-manager.io/duration"       = "${6 * (30 * 24)}h" # 6 months
    }
  }
  spec {
    backend {
      service_name = kubernetes_service.nginx.metadata[0].name
      service_port = 8080
    }
    rule {
      http {
        path {
          backend {
            service_name = kubernetes_service.nginx.metadata[0].name
            service_port = 8080
          }
          path = "/"
        }
      }
    }
    tls {
      hosts       = ["nginx.nginx.svc.cluster.local"]
      secret_name = "nginx-dot-svc-dot-cluster-dot-local"
    }
  }
}
