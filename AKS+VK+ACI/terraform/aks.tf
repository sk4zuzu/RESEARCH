
resource "random_id" "aks" {
  prefix      = "${var.env_name}-aks-"
  byte_length = 4
}

resource "azuread_application" "aks" {
  name                       = random_id.aks.hex
  available_to_other_tenants = false
}

resource "random_password" "aks" {
  special = true
  length  = 16
}

resource "azuread_application_password" "aks" {
  value                 = random_password.aks.result
  end_date_relative     = "8760h"  # one year
  application_object_id = azuread_application.aks.object_id
}

resource "azuread_service_principal" "aks" {
  application_id = azuread_application.aks.application_id
}

resource "azurerm_role_assignment" "aks" {
  role_definition_name = "Network Contributor"
  principal_id         = azuread_service_principal.aks.id
  scope                = data.azurerm_subscription.current.id
}

resource "azurerm_kubernetes_cluster" "aks" {
  depends_on = [
    azuread_service_principal.aks,
    azurerm_role_assignment.aks,
  ]

  name       = random_id.aks.hex
  dns_prefix = var.env_name

  network_profile {
    network_plugin     = "kubenet"
    docker_bridge_cidr = "172.17.0.1/16"
    pod_cidr           = "10.244.0.0/16"
    service_cidr       = cidrsubnet(var.vnet_address_space, 8, 0)
    dns_service_ip     = cidrhost(var.vnet_address_space, 10)
  }

  default_node_pool {
    name           = "default"
    node_count     = var.node_count
    vm_size        = var.node_vm_size
    vnet_subnet_id = azurerm_subnet.vnet-aks.id
  }

  service_principal {
    client_id     = azuread_application.aks.application_id
    client_secret = azuread_application_password.aks.value
  }

  tags = {
    EnvName = var.env_name
  }

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# vim:ts=2:sw=2:et:syn=terraform:
