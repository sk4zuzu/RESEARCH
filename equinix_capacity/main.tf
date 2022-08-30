data "equinix_metal_facility" "capacity_test" {
  code = var.facility

  capacity {
    plan     = var.plan
    quantity = var.quantity
  }
}

output "capacity_test" {
  value = data.equinix_metal_facility.capacity_test
}
