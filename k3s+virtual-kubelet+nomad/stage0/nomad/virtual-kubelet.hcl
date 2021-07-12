job "vk" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "service"
  update {
    stagger      = "30s"
    max_parallel = 1
  }
  group "virtual-kubelet" {
    count = 1
    task "virtual-kubelet" {
      driver = "raw_exec"
      config {
        command = "/bin/bash"
        args = [
          "-c",
          "KUBECONFIG=/etc/rancher/k3s/k3s.yaml NOMAD_ADDR=127.0.0.1:4646 NOMAD_REGION=global VK_TAINT_KEY=hashicorp.com/nomad ${prefix}/virtual-kubelet --provider=nomad",
        ]
      }
      resources {
        cpu    = 500 # MHz
        memory = 128 # MB
      }
    }
  }
}
