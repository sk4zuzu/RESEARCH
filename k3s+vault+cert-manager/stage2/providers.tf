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

provider "kubernetes-alpha" {
  config_path    = local.stage0.kubeconfig.path
  config_context = local.stage0.kubeconfig.context
}

provider "vault" {
  token   = local.stage0.vault.token
  address = local.stage0.vault.address
}
