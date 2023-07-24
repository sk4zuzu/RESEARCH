variable "auth_token" {
  type = string
}

variable "project_id" {
  type = string
}

variable "hostname" {
  type = string
}

variable "plan" {
  type    = string
  default = "c3.small.x86"
}

variable "metro" {
  type    = string
  default = "FR"
}

variable "operating_system" {
  type    = string
  default = "ubuntu_22_04"
}
