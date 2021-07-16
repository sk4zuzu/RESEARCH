locals {
  url = {
    vm = "https://raw.githubusercontent.com/kubevirt/demo/master/manifests/vm.yaml"
  }
  bin = {
    kc = abspath("${path.module}/../bin/kubectl")
  }
}

data "external" "kubevirt" {
  program = ["bash", "${path.module}/wait.sh"]
  query = {
    kc_bin = local.bin.kc
  }
}

resource "null_resource" "vm" {
  depends_on = [data.external.kubevirt]

  triggers = {
    create = "set -o errexit -o pipefail && curl -fskL ${local.url.vm} | ${local.bin.kc} create -f -"
    delete = "set -o errexit -o pipefail && curl -fskL ${local.url.vm} | ${local.bin.kc} delete -f -"
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = self.triggers.create
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["bash", "-c"]
    command     = self.triggers.delete
  }
}
