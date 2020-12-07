resource "azurerm_virtual_network" "azure-ubuntu" {
  name = random_id.azure-ubuntu.hex

  address_space = [ var.address_space ]

  location            = azurerm_resource_group.azure-ubuntu.location
  resource_group_name = azurerm_resource_group.azure-ubuntu.name
}

resource "azurerm_subnet" "azure-ubuntu" {
  name = random_id.azure-ubuntu.hex

  address_prefixes = [ cidrsubnet(var.address_space, 8, 240) ]  # 10.0.240.0/24

  virtual_network_name = azurerm_virtual_network.azure-ubuntu.name
  resource_group_name  = azurerm_resource_group.azure-ubuntu.name
}
