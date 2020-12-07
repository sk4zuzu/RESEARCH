resource "null_resource" "azure-ubuntu-basics" {
  depends_on = [ data.azurerm_public_ip.azure-ubuntu ]

  count = var._count

  connection {
    type = "ssh"
    user = "ubuntu"
    host = data.azurerm_public_ip.azure-ubuntu[count.index].ip_address
    agent = true
  }

  provisioner "remote-exec" {
    scripts = [ "${path.root}/remote-exec/01-basics.sh" ]
  }
}

resource "null_resource" "azure-ubuntu-docker" {
  depends_on = [
    data.azurerm_public_ip.azure-ubuntu,
    null_resource.azure-ubuntu-basics,
  ]

  count = var.install_docker ? var._count : 0

  connection {
    type = "ssh"
    user = "ubuntu"
    host = data.azurerm_public_ip.azure-ubuntu[count.index].ip_address
    agent = true
  }

  provisioner "remote-exec" {
    scripts = [ "${path.root}/remote-exec/02-docker.sh" ]
  }
}
