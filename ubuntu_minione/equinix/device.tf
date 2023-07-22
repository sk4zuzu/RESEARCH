resource "equinix_metal_device" "self" {
  hostname         = var.hostname
  plan             = var.plan
  metro            = var.metro
  operating_system = var.operating_system
  billing_cycle    = "hourly"
  project_id       = var.project_id
}
