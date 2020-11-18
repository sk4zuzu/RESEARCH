output "_ip" {
  value = data.azurerm_public_ip.epicli.ip_address
}

output "_ssh" {
  value = "ssh -i ${abspath(local_file.epicli-id_rsa.filename)} ubuntu@${data.azurerm_public_ip.epicli.ip_address}"
}
