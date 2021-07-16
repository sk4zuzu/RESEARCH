locals {
  kubevirt_version = "v0.43.0"
  url = {
    op = "https://github.com/kubevirt/kubevirt/releases/download/${local.kubevirt_version}/kubevirt-operator.yaml"
    cr = "https://github.com/kubevirt/kubevirt/releases/download/${local.kubevirt_version}/kubevirt-cr.yaml"
  }
  bin = {
    kc = abspath("${path.module}/../bin/kubectl")
  }
}

resource "null_resource" "op" {
  depends_on = []

  triggers = {
    create = "set -o errexit -o pipefail && curl -fskL ${local.url.op} | ${local.bin.kc} create -f -"
    delete = "set -o errexit -o pipefail && curl -fskL ${local.url.op} | ${local.bin.kc} delete -f -"
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

resource "null_resource" "cr" {
  depends_on = [null_resource.op]

  triggers = {
    create = "set -o errexit -o pipefail && curl -fskL ${local.url.cr} | ${local.bin.kc} create -f -"
    delete = "set -o errexit -o pipefail && curl -fskL ${local.url.cr} | ${local.bin.kc} delete -f -"
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
