terraform {
  required_providers {
    argocd = {
      source  = "oboukili/argocd"
      version = ">= 1.0.0"
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

provider "argocd" {
  server_addr = element(split("://", local.stage0.argocd.address), 1)
  username    = local.stage0.argocd.user
  password    = local.stage0.argocd.pass
  insecure    = true
}
