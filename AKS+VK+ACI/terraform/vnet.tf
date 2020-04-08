
resource "random_id" "vnet" {
  prefix      = "${var.env_name}-vnet-"
  byte_length = 4
}

resource "azurerm_virtual_network" "vnet" {
  name          = random_id.vnet.hex
  address_space = [ var.vnet_address_space ]

  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "vnet-aks" {
  name           = "${random_id.vnet.hex}-aks"
  address_prefix = var.aks_address_prefix

  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "vnet-aci" {
  name           = "${random_id.vnet.hex}-aci"
  address_prefix = var.aci_address_prefix

  delegation {
    name = "aciDelegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = [ "Microsoft.Network/virtualNetworks/subnets/action" ]
    }
  }

  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
}

# vim:ts=2:sw=2:et:syn=terraform:
