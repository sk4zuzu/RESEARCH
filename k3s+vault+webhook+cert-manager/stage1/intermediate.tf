resource "vault_pki_secret_backend" "intermediate" {
  path                      = "pki_int"
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 4 * (365 * 24 * 3600) # 4 years
}

resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate" {
  backend     = vault_pki_secret_backend.intermediate.path
  type        = "internal"
  common_name = "svc.cluster.local"
}

resource "vault_pki_secret_backend_root_sign_intermediate" "intermediate" {
  backend              = vault_pki_secret_backend.certmanager.path # root
  csr                  = vault_pki_secret_backend_intermediate_cert_request.intermediate.csr
  common_name          = "intermediate"
  ttl                  = "${4 * (365 * 24)}h" # 4 years
  exclude_cn_from_sans = true
}

resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate" {
  backend     = vault_pki_secret_backend.intermediate.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.intermediate.certificate
}

resource "vault_pki_secret_backend_role" "intermediate" {
  backend          = vault_pki_secret_backend.intermediate.path
  name             = "svc-dot-cluster-dot-local"
  max_ttl          = "${4 * (365 * 24)}h" # 4 years
  allow_ip_sans    = true
  key_type         = "rsa"
  key_bits         = 2048
  key_usage        = ["DigitalSignature", "KeyAgreement", "KeyEncipherment"]
  allowed_domains  = ["svc.cluster.local"]
  allow_subdomains = true
}

resource "vault_pki_secret_backend_config_urls" "intermediate" {
  backend              = vault_pki_secret_backend.intermediate.path
  issuing_certificates = ["http://vault.vault.svc:8200/v1/pki/ca"]
}

resource "vault_policy" "intermediate" {
  name   = "intermediate"
  policy = <<EOT
path "pki_int*"                                { capabilities = ["read", "list"] }
path "pki_int/roles/svc-dot-cluster-dot-local" { capabilities = ["create", "update"] }
path "pki_int/sign/svc-dot-cluster-dot-local"  { capabilities = ["create", "update"] }
path "pki_int/issue/svc-dot-cluster-dot-local" { capabilities = ["create"] }
EOT
}

resource "vault_kubernetes_auth_backend_role" "intermediate" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "intermediate"
  bound_service_account_names      = ["*"]
  bound_service_account_namespaces = ["*"]
  token_ttl                        = 3600
  token_policies                   = [vault_policy.intermediate.name]
}
