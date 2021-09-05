provider "kubernetes" {
  config_path    = var.kubeconfig.path
  config_context = var.kubeconfig.context
  experiments {
    manifest_resource = true
  }
}

provider "helm" {
  kubernetes {
    config_path    = var.kubeconfig.path
    config_context = var.kubeconfig.context
  }
}
