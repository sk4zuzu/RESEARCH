
include {
  path = "${find_in_parent_folders()}"
}

terraform {
  source = "../../terraform"
}

prevent_destroy = false

inputs = {
  location = "northeurope"
  env_name = "kub1"

  vnet_subnet_range    = "10.0.0.0/8"
  master_subnet_range  = "10.240.0.0/16"
  compute_subnet_range = "10.241.0.0/16"

  source_image_id = "/subscriptions/2d60775f-932a-4cf6-b9f0-548a8b43b368/resourceGroups/mop-research-common/providers/Microsoft.Compute/images/kubelo-20200420-145039-1587387039"

  public_key = fileexists("~/.ssh/id_research.pub") ? trimspace(file("~/.ssh/id_research.pub")) : trimspace(file("~/.ssh/id_rsa.pub"))

  master_count  = 1
  compute_count = 2

  config_storage_account_name   = "mop"
  config_storage_container_name = "mop-kubelo"
}

# vim:ts=2:sw=2:et:syn=terraform: