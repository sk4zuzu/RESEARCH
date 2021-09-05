resource "null_resource" "null" {
  provisioner "local-exec" {
    command = "${path.module}/local-exec/01-ensure-cni-mounts.sh"
  }
}
