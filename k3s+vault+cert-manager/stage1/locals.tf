locals {
  stage0             = data.terraform_remote_state.stage0.outputs
  kubernetes_ca_cert = base64decode(yamldecode(file(local.stage0.kubeconfig.path)).clusters[0].cluster["certificate-authority-data"])
}
