
variable "location" {
  type = string
}

variable "env_name" {
  type = string
}

variable "vnet_address_space" {
  type = string
  default = "10.0.0.0/8"
}

variable "master_address_prefix" {
  type = string
  default = "10.240.0.0/16"
}

variable "compute_address_prefix" {
  type = string
  default = "10.241.0.0/16"
}

variable "source_image_id" {
  type = string
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

variable "config_storage_account_name" {
  type = string
}

variable "config_storage_container_name" {
  type = string
}

# vim:ts=2:sw=2:et:syn=terraform:
