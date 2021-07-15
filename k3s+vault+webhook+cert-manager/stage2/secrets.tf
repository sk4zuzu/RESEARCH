resource "vault_generic_secret" "secrets" {
  for_each = {
    sec1 = {
      aaa = "123"
      bbb = "456"
    }
  }
  path = "secret/kubernetes/${each.key}"
  data_json = jsonencode({
    aaa = each.value["aaa"]
    bbb = each.value["bbb"]
  })
}

resource "kubernetes_secret" "secrets" {
  depends_on = [vault_generic_secret.secrets]
  for_each   = vault_generic_secret.secrets
  metadata {
    namespace = kubernetes_namespace.nginx.metadata[0].name
    name      = each.key
    annotations = {
      "vault.security.banzaicloud.io/vault-addr"        = "http://vault.vault.svc:8200"
      "vault.security.banzaicloud.io/vault-skip-verify" = "true"
      "vault.security.banzaicloud.io/vault-path"        = "kubernetes"
      "vault.security.banzaicloud.io/vault-role"        = "kubernetes"
    }
  }
  data = {
    aaa = "vault:secret/data/kubernetes/${each.key}#aaa"
    bbb = "vault:secret/data/kubernetes/${each.key}#bbb"
  }
}
