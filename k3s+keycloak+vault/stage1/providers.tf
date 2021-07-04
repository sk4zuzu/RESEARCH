terraform {
  required_providers {
    keycloak = {
      source  = "mrparkers/keycloak"
      version = ">= 3.0.0"
    }
  }
}

data "terraform_remote_state" "stage0" {
  backend = "local"
  config = {
    path = abspath("${path.module}/../stage0/terraform.tfstate")
  }
}

provider "kubernetes" {
  config_path    = local.stage0.kubeconfig.path
  config_context = local.stage0.kubeconfig.context
}

provider "helm" {
  kubernetes {
    config_path    = local.stage0.kubeconfig.path
    config_context = local.stage0.kubeconfig.context
  }
}

provider "vault" {
  token   = local.stage0.vault.token
  address = local.stage0.vault.address
}

provider "keycloak" {
  client_id = "admin-cli"
  username  = local.stage0.keycloak.user
  password  = local.stage0.keycloak.pass
  url       = local.stage0.keycloak.address
}
