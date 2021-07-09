variable "kubeconfig" {
  type = object({
    path    = string
    context = string
  })
  default = {
    path    = "~/.kube/k3s.yaml"
    context = "default"
  }
}
