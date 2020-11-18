resource "azurerm_resource_group" "epicli" {
  name     = random_id.epicli.hex
  location = var.location
}
