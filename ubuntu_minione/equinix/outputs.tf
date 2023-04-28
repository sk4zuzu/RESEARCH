output "public_ipv4" {
  value = equinix_metal_device.self.network[0].address
}

output "private_ipv4" {
  value = equinix_metal_device.self.network[2].address
}
