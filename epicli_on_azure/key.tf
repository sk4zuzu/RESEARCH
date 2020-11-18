resource "tls_private_key" "epicli" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "epicli-id_rsa" {
  filename        = "${path.root}/id_rsa"
  file_permission = "0600"

  content = tls_private_key.epicli.private_key_pem
}

resource "local_file" "epicli-id_rsa-pub" {
  filename        = "${path.root}/id_rsa.pub"
  file_permission = "0600"

  content = tls_private_key.epicli.public_key_openssh
}
