resource "null_resource" "epicli-prepare" {
  depends_on = [ data.azurerm_public_ip.epicli ]

  connection {
    type = "ssh"
    user = "ubuntu"
    host = data.azurerm_public_ip.epicli.ip_address
    private_key = tls_private_key.epicli.private_key_pem
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.root}/remote-exec/01-basics.sh",
      "${path.root}/remote-exec/02-docker.sh",
    ]
  }
}

resource "null_resource" "epicli-clone-epiphany-offline" {
  depends_on = [
    data.azurerm_public_ip.epicli,
    null_resource.epicli-prepare,
  ]

  connection {
    type = "ssh"
    user = "ubuntu"
    host = data.azurerm_public_ip.epicli.ip_address
    private_key = tls_private_key.epicli.private_key_pem
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.root}/remote-exec/03-clone-epiphany-offline.sh",
    ]
  }
}

resource "null_resource" "epicli-clone-epiphany" {
  depends_on = [
    data.azurerm_public_ip.epicli,
    null_resource.epicli-prepare,
  ]

  connection {
    type = "ssh"
    user = "ubuntu"
    host = data.azurerm_public_ip.epicli.ip_address
    private_key = tls_private_key.epicli.private_key_pem
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.root}/remote-exec/03-clone-epiphany.sh",
    ]
  }
}
