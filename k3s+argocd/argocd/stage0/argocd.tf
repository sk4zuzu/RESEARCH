resource "helm_release" "argocd" {
  create_namespace = true
  namespace        = "argocd"
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  values = [
    yamlencode({
      server = {
        extraArgs = ["--insecure"]
        ingress = {
          enabled = true
          https   = false
          hosts   = ["argocd"]
          paths   = ["/"]
        }
      }
    })
  ]
}

data "kubernetes_service" "argocd" {
  metadata {
    namespace = "argocd"
    name      = "${helm_release.argocd.metadata[0].name}-server"
  }
}

data "kubernetes_secret" "argocd" {
  metadata {
    namespace = "argocd"
    name      = "${helm_release.argocd.metadata[0].name}-initial-admin-secret"
  }
}
