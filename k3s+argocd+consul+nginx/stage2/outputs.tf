output "apps" {
  value = {
    nginx1 = argocd_application.nginx1
    nginx2 = argocd_application.nginx2
  }
}
