output "repos" {
  value = {
    git = argocd_repository.git
  }
}
