data "kubernetes_service_account" "certmanager" {
  metadata {
    namespace = local.stage0.certmanager.namespace
    name      = "${local.stage0.certmanager.name}-cert-manager"
  }
}

resource "kubernetes_manifest" "certmanager" {
  provider = kubernetes-alpha
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "cluster-issuer"
    }
    spec = {
      vault = {
        path   = "pki_int/sign/svc-dot-cluster-dot-local"
        server = "http://vault.vault.svc:8200"
        auth = {
          kubernetes = {
            role      = "intermediate"
            mountPath = "/v1/auth/kubernetes"
            secretRef = {
              name = data.kubernetes_service_account.certmanager.default_secret_name
              key  = "token"
            }
          }
        }
      }
    }
  }
}
