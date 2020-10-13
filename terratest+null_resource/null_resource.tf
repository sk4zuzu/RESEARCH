terraform {
  required_version = ">= 0.13.0"
}

resource "null_resource" "x" {
  provisioner "local-exec" {
    command = "echo prprpr"
  }
}
