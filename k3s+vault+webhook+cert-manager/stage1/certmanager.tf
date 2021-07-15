resource "vault_pki_secret_backend" "certmanager" {
  path                      = "pki"
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 10 * (365 * 24 * 3600) # 10 years
}

resource "vault_pki_secret_backend_root_cert" "certmanager" {
  backend              = vault_pki_secret_backend.certmanager.path
  type                 = "internal"
  common_name          = "certmanager"
  ttl                  = "${10 * (365 * 24)}h" # 10 years
  format               = "pem"
  private_key_format   = "der"
  key_type             = "rsa"
  key_bits             = 2048
  exclude_cn_from_sans = true
}

resource "vault_pki_secret_backend_role" "certmanager" {
  backend          = vault_pki_secret_backend.certmanager.path
  name             = "cluster-dot-local"
  max_ttl          = "87600h"
  allow_ip_sans    = true
  key_type         = "rsa"
  key_bits         = 2048
  key_usage        = ["DigitalSignature", "KeyAgreement", "KeyEncipherment"]
  allowed_domains  = ["cluster.local"]
  allow_subdomains = true
}

resource "vault_pki_secret_backend_config_urls" "certmanager" {
  backend              = vault_pki_secret_backend.certmanager.path
  issuing_certificates = ["http://vault.vault.svc:8200/v1/pki/ca"]
}

resource "vault_policy" "certmanager" {
  name   = "certmanager"
  policy = <<EOT
path "pki*"                        { capabilities = ["read", "list"] }
path "pki/roles/cluster-dot-local" { capabilities = ["create", "update"] }
path "pki/sign/cluster-dot-local"  { capabilities = ["create", "update"] }
path "pki/issue/cluster-dot-local" { capabilities = ["create"] }
EOT
}

resource "vault_kubernetes_auth_backend_role" "certmanager" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "certmanager"
  bound_service_account_names      = ["*"]
  bound_service_account_namespaces = ["*"]
  token_ttl                        = 3600
  token_policies                   = [vault_policy.certmanager.name]
}
