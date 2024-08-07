resource "kubernetes_manifest" "cnao" {
  depends_on = [null_resource.null]

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name       = "cnao-op"
      namespace  = "argocd"
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }

    spec = {
      project = "default"

      source = {
        repoURL        = "https://github.com/sk4zuzu/RESEARCH.git"
        targetRevision = "argocd"
        path           = "./k3s+argocd/kubevirt+k3s/stage0/manifests/cnao/"
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
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }
}
