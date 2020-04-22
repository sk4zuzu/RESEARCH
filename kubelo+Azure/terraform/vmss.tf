
resource "random_id" "vmss" {
  prefix      = "${var.env_name}-vmss-"
  byte_length = 4
}

resource "azurerm_linux_virtual_machine_scale_set" "vmss-master" {
  name = "${random_id.vmss.hex}-master"

  sku       = "Standard_B2s"
  instances = var.master_count

  admin_username = "ubuntu"

  admin_ssh_key {
    username   = "ubuntu"
    public_key = var.public_key
  }

  source_image_id = var.source_image_id

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "primary"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.vnet-master.id

      public_ip_address {
        name = "external"
      }
    }
  }

  tags = {
    EnvName  = var.env_name
    RoleName = "master"
  }

  lifecycle {
    ignore_changes = [ instances ]
  }

  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_linux_virtual_machine_scale_set" "vmss-compute" {
  name = "${random_id.vmss.hex}-compute"

  sku       = "Standard_B2s"
  instances = var.compute_count

  admin_username = "ubuntu"

  admin_ssh_key {
    username   = "ubuntu"
    public_key = var.public_key
  }

  source_image_id = var.source_image_id

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "primary"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.vnet-compute.id
    }
  }

  tags = {
    EnvName  = var.env_name
    RoleName = "compute"
  }

  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# vim:ts=2:sw=2:et:syn=terraform:
