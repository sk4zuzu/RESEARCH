resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  values = [
    yamlencode({
      server = {
        extraArgs = ["--insecure"]
        ingress = {
          enabled = true
          https   = false
          hosts   = ["argocd.argocd.svc"]
          paths   = ["/"]
        }
      }
    })
  ]
}

data "kubernetes_service" "argocd" {
  metadata {
    namespace = kubernetes_namespace.argocd.metadata[0].name
    name      = "${helm_release.argocd.metadata[0].name}-server"
  }
}

data "kubernetes_secret" "argocd" {
  metadata {
    namespace = kubernetes_namespace.argocd.metadata[0].name
    name      = "${helm_release.argocd.metadata[0].name}-initial-admin-secret"
  }
}
