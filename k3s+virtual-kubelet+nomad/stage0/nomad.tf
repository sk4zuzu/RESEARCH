resource "nomad_job" "virtualkubelet" {
  jobspec = templatefile("${path.module}/nomad/virtual-kubelet.hcl", {
    prefix = abspath(path.module)
  })
}
