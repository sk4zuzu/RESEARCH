resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }
}

resource "helm_release" "vault" {
  namespace  = kubernetes_namespace.vault.metadata[0].name
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  values = [
    yamlencode({
      server = {
        enabled = true
        dev     = { enabled = true }
      }
      injector = {
        enabled = false
      }
    })
  ]
}

resource "helm_release" "webhook" {
  namespace  = kubernetes_namespace.vault.metadata[0].name
  name       = "webhook"
  repository = "https://kubernetes-charts.banzaicloud.com"
  chart      = "vault-secrets-webhook"
}

data "kubernetes_service" "vault" {
  depends_on = [helm_release.vault]
  metadata {
    namespace = kubernetes_namespace.vault.metadata[0].name
    name      = "vault"
  }
}
