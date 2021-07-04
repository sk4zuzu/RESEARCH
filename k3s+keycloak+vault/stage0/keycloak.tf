resource "kubernetes_namespace" "keycloak" {
  metadata {
    name = "keycloak"
  }
}

resource "helm_release" "keycloak" {
  namespace  = kubernetes_namespace.keycloak.metadata[0].name
  name       = "keycloak"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "keycloak"
  values = [
    yamlencode({
      service = {
        type = "ClusterIP"
      }
      auth = {
        createAdminUser    = true
        adminUser          = "admin"
        adminPassword      = "asd"
        managementUser     = "manager"
        managementPassword = "asd"
      }
    })
  ]
}

data "kubernetes_service" "keycloak" {
  depends_on = [helm_release.keycloak]
  metadata {
    namespace = kubernetes_namespace.keycloak.metadata[0].name
    name      = "keycloak"
  }
}
