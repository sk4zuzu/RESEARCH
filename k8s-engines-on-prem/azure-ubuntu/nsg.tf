locals {
  allowed_public_tcp_ports = [ 22, 6443 ]
}

resource "azurerm_network_security_group" "azure-ubuntu" {
  name     = random_id.azure-ubuntu.hex
  location = azurerm_resource_group.azure-ubuntu.location

  dynamic "security_rule" {
    for_each = local.allowed_public_tcp_ports
    content {
      name                       = "ALLOW-${tostring(security_rule.value)}"
      priority                   = 100 + security_rule.key
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = tostring(security_rule.value)
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }

  resource_group_name = azurerm_resource_group.azure-ubuntu.name
}
