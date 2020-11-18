resource "azurerm_public_ip" "epicli" {
  name     = random_id.epicli.hex
  location = azurerm_resource_group.epicli.location

  allocation_method = "Dynamic"

  resource_group_name = azurerm_resource_group.epicli.name
}

resource "azurerm_network_interface" "epicli" {
  name     = random_id.epicli.hex
  location = azurerm_resource_group.epicli.location

  ip_configuration {
    name                          = random_id.epicli.hex
    subnet_id                     = azurerm_subnet.epicli.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.epicli.id
  }

  resource_group_name = azurerm_resource_group.epicli.name
}

resource "azurerm_network_interface_security_group_association" "epicli" {
  network_interface_id      = azurerm_network_interface.epicli.id
  network_security_group_id = azurerm_network_security_group.epicli.id
}

resource "azurerm_linux_virtual_machine" "epicli" {
  name     = random_id.epicli.hex
  location = azurerm_resource_group.epicli.location

  size = var.size

  network_interface_ids = [ azurerm_network_interface.epicli.id ]

  source_image_reference {
    publisher = var.source_image_reference.publisher
    offer     = var.source_image_reference.offer
    sku       = var.source_image_reference.sku
    version   = var.source_image_reference.version
  }

  os_disk {
    name                 = random_id.epicli.hex
    caching              = "ReadWrite"
    disk_size_gb         = var.disk_size_gb
    storage_account_type = "Standard_LRS"
  }

  disable_password_authentication = true

  admin_username = "ubuntu"

  admin_ssh_key {
    username   = "ubuntu"
    public_key = tls_private_key.epicli.public_key_openssh
  }

  resource_group_name = azurerm_resource_group.epicli.name
}

data "azurerm_public_ip" "epicli" {
  depends_on          = [ azurerm_linux_virtual_machine.epicli ]
  name                = azurerm_public_ip.epicli.name
  resource_group_name = azurerm_resource_group.epicli.name
}
