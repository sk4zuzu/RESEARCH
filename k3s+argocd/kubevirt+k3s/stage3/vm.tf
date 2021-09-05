resource "kubernetes_manifest" "vm" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name       = "vm"
      namespace  = "argocd"
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }

    spec = {
      project = "default"

      source = {
        repoURL        = "https://github.com/sk4zuzu/RESEARCH.git"
        targetRevision = "argocd"
        path           = "./k3s+argocd/kubevirt+k3s/stage3/manifests/vm/"
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "cluster-network-addons"
      }

      syncPolicy = {
        automated = {
          prune      = true
          selfHeal   = false
          allowEmpty = false
        }
        syncOptions = ["CreateNamespace=false"]
      }
    }
  }
}
