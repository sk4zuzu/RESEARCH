terraform {
  required_providers {
    metal = {
      source = "equinix/metal"
      version = "3.2.2"
    }
  }
}

provider "metal" {
  auth_token = var.auth_token
}
