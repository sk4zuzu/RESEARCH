
terraform {
  backend "s3" {}
}

provider "aws" {}

provider "external" {}

provider "local" {}

provider "random" {}

# vim:ts=2:sw=2:et:syn=terraform:
