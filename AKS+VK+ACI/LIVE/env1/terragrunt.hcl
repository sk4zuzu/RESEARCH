
include {
  path = "${find_in_parent_folders()}"
}

terraform {
  source = "../../terraform"
}

prevent_destroy = false

inputs = {
  location = "northeurope"
  env_name = "env1"

  vnet_subnet_range = "10.0.0.0/8"
  aks_subnet_range  = "10.240.0.0/16"
  aci_subnet_range  = "10.241.0.0/16"

  enable_provisioning = true
}

# vim:ts=2:sw=2:et:syn=terraform:
