resource "azurerm_resource_group" "azure-ubuntu" {
  name     = random_id.azure-ubuntu.hex
  location = var.location
}
