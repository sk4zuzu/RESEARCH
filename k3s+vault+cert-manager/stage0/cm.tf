resource "kubernetes_namespace" "cm" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cm" {
  namespace  = kubernetes_namespace.cm.metadata[0].name
  name       = "cm"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  values = [
    yamlencode({
      replicaCount = 1
      installCRDs  = true
    })
  ]
}
