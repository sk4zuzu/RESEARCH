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
