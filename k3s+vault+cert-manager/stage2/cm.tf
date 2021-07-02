resource "kubernetes_secret" "cm" {
  metadata {
    namespace = local.stage0.cm.namespace
    name      = "vault-token"
  }
  data = {
    token = local.stage0.vault.token_reviewer_jwt
  }
}

resource "kubernetes_manifest" "issuer" {
  provider = kubernetes-alpha
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "vault-issuer"
    }
    spec = {
      vault = {
        path   = "pki/sign/svc-dot-cluster-dot-local"
        server = "http://vault.vault.svc:8200"
        auth = {
          kubernetes = {
            role      = "cm"
            mountPath = "/v1/auth/kubernetes"
            secretRef = {
              name = kubernetes_secret.cm.metadata[0].name
              key  = "token"
            }
          }
        }
      }
    }
  }
}
