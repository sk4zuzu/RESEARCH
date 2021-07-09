provider "kubernetes" {
  config_path    = var.kubeconfig.path
  config_context = var.kubeconfig.context
}

provider "helm" {
  kubernetes {
    config_path    = var.kubeconfig.path
    config_context = var.kubeconfig.context
  }
}
