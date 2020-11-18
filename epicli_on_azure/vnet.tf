resource "azurerm_virtual_network" "epicli" {
  name = random_id.epicli.hex

  address_space = [ var.address_space ]

  location            = azurerm_resource_group.epicli.location
  resource_group_name = azurerm_resource_group.epicli.name
}

resource "azurerm_subnet" "epicli" {
  name = random_id.epicli.hex

  address_prefixes = [ cidrsubnet(var.address_space, 8, 240) ]  # 10.0.240.0/24

  virtual_network_name = azurerm_virtual_network.epicli.name
  resource_group_name  = azurerm_resource_group.epicli.name
}
