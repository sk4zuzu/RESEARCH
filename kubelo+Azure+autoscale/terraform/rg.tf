
resource "random_id" "rg" {
  prefix      = "${var.env_name}-rg-"
  byte_length = 4
}

resource "azurerm_resource_group" "rg" {
  name     = random_id.rg.hex
  location = var.location
}

# vim:ts=2:sw=2:et:syn=terraform:
