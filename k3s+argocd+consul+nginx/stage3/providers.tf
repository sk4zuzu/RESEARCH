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

data "terraform_remote_state" "stage1" {
  backend = "local"
  config = {
    path = abspath("${path.module}/../stage1/terraform.tfstate")
  }
}

provider "kubernetes" {
  config_path    = local.stage0.kubeconfig.path
  config_context = local.stage0.kubeconfig.context
}

provider "argocd" {
  server_addr = element(split("://", local.stage0.argocd.address), 1)
  grpc_web    = true
  plain_text  = true
  insecure    = true
  username    = local.stage0.argocd.user
  password    = local.stage0.argocd.pass
}
