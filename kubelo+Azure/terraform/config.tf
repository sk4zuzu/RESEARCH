
resource "azurerm_storage_blob" "config-terragrunt" {
  name = "terragrunt.hcl"
  type = "Block"

  source_content = file("${path.module}/../../../../../LIVE/terragrunt.hcl")

  storage_account_name   = var.config_storage_account_name
  storage_container_name = var.config_storage_container_name
}

resource "azurerm_storage_blob" "config-environment" {
  name = "${var.env_name}/terragrunt.hcl"
  type = "Block"

  source_content = file("${path.module}/../../../../../LIVE/${var.env_name}/terragrunt.hcl")

  storage_account_name   = var.config_storage_account_name
  storage_container_name = var.config_storage_container_name
}

# vim:ts=2:sw=2:et:syn=terraform:
