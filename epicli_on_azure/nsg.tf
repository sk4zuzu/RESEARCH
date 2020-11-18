resource "azurerm_network_security_group" "epicli" {
  name     = random_id.epicli.hex
  location = azurerm_resource_group.epicli.location

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  resource_group_name = azurerm_resource_group.epicli.name
}
