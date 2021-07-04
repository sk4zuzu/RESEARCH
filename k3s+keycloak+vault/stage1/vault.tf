resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = "https://kubernetes.default.svc"
  kubernetes_ca_cert     = local.kubernetes_ca_cert
  token_reviewer_jwt     = local.stage0.vault.token_reviewer_jwt
  disable_iss_validation = true
}

resource "vault_policy" "kubernetes" {
  name   = "kubernetes"
  policy = <<EOT
path "secret/data/kubernetes/*" {
  capabilities = ["read"]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "kubernetes" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "kubernetes"
  bound_service_account_names      = ["*"]
  bound_service_account_namespaces = ["*"]
  token_ttl                        = 3600
  token_policies                   = [vault_policy.kubernetes.name]
}
