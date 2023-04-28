resource "equinix_metal_device" "self" {
  hostname         = var.hostname
  plan             = var.plan
  facilities       = var.facilities
  operating_system = var.operating_system
  billing_cycle    = "hourly"
  project_id       = var.project_id
}
