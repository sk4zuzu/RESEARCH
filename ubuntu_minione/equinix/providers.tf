terraform {
  required_providers {
    equinix = {
      source = "equinix/equinix"
      version = "1.14.3"
    }
  }
}

provider "equinix" {
  auth_token = var.auth_token
}
