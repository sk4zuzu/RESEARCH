terraform {
  required_providers {
    equinix = {
      source = "equinix/equinix"
      version = "1.8.1"
    }
  }
}

provider "equinix" {
  auth_token = var.auth_token
}
