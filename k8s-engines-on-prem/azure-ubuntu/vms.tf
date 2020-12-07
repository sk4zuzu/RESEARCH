resource "azurerm_public_ip" "azure-ubuntu" {
  count    = var._count
  name     = "${random_id.azure-ubuntu.hex}-${count.index}"
  location = azurerm_resource_group.azure-ubuntu.location

  allocation_method = "Dynamic"

  resource_group_name = azurerm_resource_group.azure-ubuntu.name
}

resource "azurerm_network_interface" "azure-ubuntu" {
  count    = var._count
  name     = "${random_id.azure-ubuntu.hex}-${count.index}"
  location = azurerm_resource_group.azure-ubuntu.location

  ip_configuration {
    name                          = random_id.azure-ubuntu.hex
    subnet_id                     = azurerm_subnet.azure-ubuntu.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azure-ubuntu[count.index].id
  }

  resource_group_name = azurerm_resource_group.azure-ubuntu.name
}

resource "azurerm_network_interface_security_group_association" "azure-ubuntu" {
  count                     = var._count
  network_interface_id      = azurerm_network_interface.azure-ubuntu[count.index].id
  network_security_group_id = azurerm_network_security_group.azure-ubuntu.id
}

resource "azurerm_linux_virtual_machine" "azure-ubuntu" {
  count    = var._count
  name     = "${random_id.azure-ubuntu.hex}-${count.index}"
  location = azurerm_resource_group.azure-ubuntu.location

  size = var.size

  network_interface_ids = [ azurerm_network_interface.azure-ubuntu[count.index].id ]

  source_image_reference {
    publisher = var.source_image_reference.publisher
    offer     = var.source_image_reference.offer
    sku       = var.source_image_reference.sku
    version   = var.source_image_reference.version
  }

  os_disk {
    name                 = "${random_id.azure-ubuntu.hex}-${count.index}"
    caching              = "ReadWrite"
    disk_size_gb         = var.disk_size_gb
    storage_account_type = "Standard_LRS"
  }

  disable_password_authentication = true

  admin_username = "ubuntu"

  admin_ssh_key {
    username   = "ubuntu"
    public_key = file(var.public_key_path)
  }

  resource_group_name = azurerm_resource_group.azure-ubuntu.name
}

data "azurerm_public_ip" "azure-ubuntu" {
  depends_on          = [ azurerm_linux_virtual_machine.azure-ubuntu ]
  count               = var._count
  name                = azurerm_public_ip.azure-ubuntu[count.index].name
  resource_group_name = azurerm_resource_group.azure-ubuntu.name
}
