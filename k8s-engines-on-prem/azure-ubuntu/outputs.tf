output "kubeone" {
  value = yamlencode({
    "nodes": [
      for index in range(var._count):
      {
        "publicAddress": data.azurerm_public_ip.azure-ubuntu[index].ip_address,
        "privateAddress": azurerm_network_interface.azure-ubuntu[index].private_ip_address,
      }
    ],
  })
}

output "kubespray" {
  value = yamlencode({
    "nodes": [
      for index in range(var._count):
      "node${index+1} ansible_host=${data.azurerm_public_ip.azure-ubuntu[index].ip_address} ip=${azurerm_network_interface.azure-ubuntu[index].private_ip_address}"
    ],
  })
}

output "rke" {
  value = yamlencode({
    "nodes": [
      for index in range(var._count):
      {
        "address": data.azurerm_public_ip.azure-ubuntu[index].ip_address,
        "internal_address": azurerm_network_interface.azure-ubuntu[index].private_ip_address,
      }
    ],
  })
}

output "ssh" {
  value = [
    for ip_address in data.azurerm_public_ip.azure-ubuntu.*.ip_address:
    "ssh ubuntu@${ip_address}"
  ]
}
