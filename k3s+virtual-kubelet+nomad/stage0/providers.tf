provider "kubernetes" {
  config_path    = var.kubeconfig.path
  config_context = var.kubeconfig.context
}

provider "nomad" {
  address = "http://127.0.0.1:4646"
  region  = "global"
}
