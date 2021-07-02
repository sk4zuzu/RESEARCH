resource "vault_pki_secret_backend" "cm" {
  path                      = "pki"
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 315360000 # 10 years
}

resource "vault_pki_secret_backend_root_cert" "cm" {
  backend               = vault_pki_secret_backend.cm.path
  type                  = "internal"
  common_name           = "CM"
  ttl                   = "87600h" # 10 years
  format                = "pem"
  private_key_format    = "der"
  key_type              = "rsa"
  key_bits              = 2048
  exclude_cn_from_sans  = true
}

resource "vault_pki_secret_backend_role" "cm" {
  backend          = vault_pki_secret_backend.cm.path
  name             = "svc-dot-cluster-dot-local"
  max_ttl          = "87600h"
  allow_ip_sans    = true
  key_type         = "rsa"
  key_bits         = 2048
  key_usage        = ["DigitalSignature", "KeyAgreement", "KeyEncipherment"]
  allowed_domains  = ["svc.cluster.local"]
  allow_subdomains = true
}

resource "vault_pki_secret_backend_config_urls" "cm" {
  backend              = vault_pki_secret_backend.cm.path
  issuing_certificates = ["http://vault.vault.svc:8200/v1/pki/ca"]
}

resource "vault_policy" "cm" {
  name   = "cm"
  policy = <<EOT
path "pki*"                                { capabilities = ["read", "list"] }
path "pki/roles/svc-dot-cluster-dot-local" { capabilities = ["create", "update"] }
path "pki/sign/svc-dot-cluster-dot-local"  { capabilities = ["create", "update"] }
path "pki/issue/svc-dot-cluster-dot-local" { capabilities = ["create"] }
EOT
}

resource "vault_kubernetes_auth_backend_role" "cm" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "cm"
  bound_service_account_names      = ["*"]
  bound_service_account_namespaces = ["*"]
  token_ttl                        = 3600
  token_policies                   = [vault_policy.cm.name]
}
