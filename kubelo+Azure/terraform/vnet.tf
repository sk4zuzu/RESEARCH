
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

resource "azurerm_subnet" "vnet-master" {
  name           = "${random_id.vnet.hex}-master"
  address_prefix = var.master_address_prefix

  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "vnet-compute" {
  name           = "${random_id.vnet.hex}-compute"
  address_prefix = var.compute_address_prefix

  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
}

# vim:ts=2:sw=2:et:syn=terraform:
