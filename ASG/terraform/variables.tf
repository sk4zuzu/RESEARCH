
variable "region" {
  type = string
}

variable "env_name" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
  default = "10.0.0.0/16"
}

variable "master_cidr_block" {
  type = string
  default = "10.0.240.0/24"
}

variable "compute_cidr_block" {
  type = string
  default = "10.0.241.0/24"
}

variable "public_key" {
  type = string
}

variable "master_count" {
  type = number
}

variable "compute_count" {
  type = number
}

variable "SG_ALLOWED_ADDRESS" {
  type = string
}

# vim:ts=2:sw=2:et:syn=terraform:
