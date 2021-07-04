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
    })
  ]
}

data "kubernetes_service" "vault" {
  depends_on = [helm_release.vault]
  metadata {
    namespace = kubernetes_namespace.vault.metadata[0].name
    name      = "vault"
  }
}

data "external" "kubernetes" {
  program = ["bash", "${path.module}/external/token.sh"]
  query = {
    kubeconfig = pathexpand(var.kubeconfig.path)
    context    = var.kubeconfig.context
    namespace  = kubernetes_namespace.vault.metadata[0].name
    pattern    = "${helm_release.vault.metadata[0].name}-token-"
  }
}
