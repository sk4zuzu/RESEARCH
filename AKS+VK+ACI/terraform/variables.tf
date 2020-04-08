
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

variable "aks_address_prefix" {
  type = string
  default = "10.240.0.0/16"
}

variable "aci_address_prefix" {
  type = string
  default = "10.241.0.0/16"
}

variable "node_count" {
  type = string
  default = "1"
}

variable "node_vm_size" {
  type = string
  default = "Standard_D1_v2"
}

variable "enable_provisioning" {
  type = bool
  default = true
}

# vim:ts=2:sw=2:et:syn=terraform:
