
terraform {
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

provider "external" {}

provider "null" {}

provider "random" {}

# vim:ts=2:sw=2:et:syn=terraform:
