resource "keycloak_realm" "keycloak" {
  enabled = true
  realm   = "keycloak"
}

resource "keycloak_user" "keycloak" {
  enabled  = true
  realm_id = keycloak_realm.keycloak.id
  username = "keycloak"
  initial_password {
    value     = "asd"
    temporary = false
  }
}

resource "keycloak_openid_client" "keycloak" {
  enabled               = true
  realm_id              = keycloak_realm.keycloak.id
  client_id             = "vault"
  name                  = "vault"
  standard_flow_enabled = true
  access_type           = "CONFIDENTIAL"
  valid_redirect_uris   = ["${local.stage0.vault.address}/*"]
  login_theme           = "keycloak"
}

resource "keycloak_role" "reader" {
  realm_id  = keycloak_realm.keycloak.id
  client_id = keycloak_openid_client.keycloak.id
  name      = "reader"
}

resource "keycloak_role" "management" {
  realm_id        = keycloak_realm.keycloak.id
  client_id       = keycloak_openid_client.keycloak.id
  name            = "management"
  composite_roles = [keycloak_role.reader.id]
}

resource "keycloak_openid_user_client_role_protocol_mapper" "keycloak" {
  realm_id    = keycloak_realm.keycloak.id
  client_id   = keycloak_openid_client.keycloak.id
  name        = "user-client-role-mapper"
  claim_name  = "resource_access.${keycloak_openid_client.keycloak.client_id}.roles"
  multivalued = true
}

resource "vault_identity_oidc_key" "keycloak" {
  name      = "keycloak"
  algorithm = "RS256"
}

resource "vault_jwt_auth_backend" "keycloak" {
  path               = "oidc"
  type               = "oidc"
  default_role       = "default"
  oidc_discovery_url = "${local.stage0.keycloak.address}/auth/realms/${keycloak_realm.keycloak.id}"
  oidc_client_id     = keycloak_openid_client.keycloak.client_id
  oidc_client_secret = keycloak_openid_client.keycloak.client_secret
  tune {
    audit_non_hmac_request_keys  = []
    audit_non_hmac_response_keys = []
    default_lease_ttl            = "1h"
    listing_visibility           = "unauth"
    max_lease_ttl                = "1h"
    passthrough_request_headers  = []
    token_type                   = "default-service"
  }
}

resource "vault_jwt_auth_backend_role" "keycloak" {
  backend         = vault_jwt_auth_backend.keycloak.path
  role_name       = "default"
  role_type       = "oidc"
  token_ttl       = 3600
  token_max_ttl   = 3600
  bound_audiences = [keycloak_openid_client.keycloak.client_id]
  user_claim      = "sub"
  groups_claim    = "/resource_access/${keycloak_openid_client.keycloak.client_id}/roles"
  claim_mappings  = { preferred_username = "username" }
  allowed_redirect_uris = [
    "${local.stage0.vault.address}/ui/vault/auth/oidc/oidc/callback",
    "${local.stage0.vault.oidc_address}/oidc/callback",
  ]
}

data "vault_policy_document" "reader" {
  rule {
    path         = "/secret/*"
    capabilities = ["list", "read"]
  }
}

resource "vault_policy" "reader" {
  name   = "reader"
  policy = data.vault_policy_document.reader.hcl
}

data "vault_policy_document" "manager" {
  rule {
    path         = "/secret/*"
    capabilities = ["create", "update", "delete"]
  }
}

resource "vault_policy" "manager" {
  name   = "management"
  policy = data.vault_policy_document.manager.hcl
}

resource "vault_identity_oidc_role" "management" {
  name = "management"
  key  = vault_identity_oidc_key.keycloak.name
}

resource "vault_identity_group" "management" {
  name     = vault_identity_oidc_role.management.name
  type     = "external"
  policies = [vault_policy.manager.name]
}

resource "vault_identity_group_alias" "management" {
  name           = "management"
  mount_accessor = vault_jwt_auth_backend.keycloak.accessor
  canonical_id   = vault_identity_group.management.id
}
