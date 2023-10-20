output "public_ipv4" {
  value = {
    for k, v in equinix_metal_device.self : k => v.network[0].address
  }

}

output "private_ipv4" {
  value = {
    for k, v in equinix_metal_device.self : k => v.network[2].address
  }
}
