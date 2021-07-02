resource "vault_generic_secret" "nginx" {
  path      = "secret/kubernetes/asd"
  data_json = jsonencode({ asd = "fgh" })
}

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
        annotations = {
          "vault.hashicorp.com/agent-inject"            = "true"
          "vault.hashicorp.com/role"                    = "kubernetes"
          "vault.hashicorp.com/agent-inject-secret-asd" = vault_generic_secret.nginx.path
        }
      }
      spec {
        container {
          image = "nginx"
          name  = "nginx"
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
      "cert-manager.io/cluster-issuer" = "vault-issuer"
      "cert-manager.io/common-name"    = "nginx.nginx.svc.cluster.local"
      "cert-manager.io/duration"       = "4320h" # 6 months
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
