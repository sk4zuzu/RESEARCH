
include {
  path = "${find_in_parent_folders()}"
}

terraform {
  source = "../../terraform"
}

prevent_destroy = false

inputs = {
  region = "eu-central-1"
  env_name = "asg1"

  vpc_cidr_block = "10.0.0.0/16"

  master_cidr_block  = "10.0.240.0/24"
  compute_cidr_block = "10.0.241.0/24"

  public_key = fileexists("~/.ssh/id_research.pub") ? trimspace(file("~/.ssh/id_research.pub")) : trimspace(file("~/.ssh/id_rsa.pub"))

  master_count  = 1
  compute_count = 2
}

# vim:ts=2:sw=2:et:syn=terraform:
