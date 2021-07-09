resource "kubernetes_namespace" "certmanager" {
  metadata {
    name = "certmanager"
  }
}

resource "helm_release" "certmanager" {
  namespace  = kubernetes_namespace.certmanager.metadata[0].name
  name       = "certmanager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  values = [
    yamlencode({
      replicaCount = 1
      installCRDs  = true
    })
  ]
}
