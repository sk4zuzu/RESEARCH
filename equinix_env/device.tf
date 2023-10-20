resource "equinix_metal_device" "self" {
  for_each         = var.hosts
  hostname         = each.key
  plan             = each.value.plan
  metro            = each.value.metro
  operating_system = each.value.operating_system
  billing_cycle    = "hourly"
  project_id       = var.project_id
}
