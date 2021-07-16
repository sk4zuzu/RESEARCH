provider "null" {}

provider "kubernetes" {
  config_path    = var.kubeconfig.path
  config_context = var.kubeconfig.context
}
