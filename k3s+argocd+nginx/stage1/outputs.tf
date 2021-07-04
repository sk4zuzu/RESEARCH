output "repos" {
  value = {
    git = argocd_repository.git
  }
}

output "apps" {
  value = {
    nginx = argocd_application.nginx
  }
}
