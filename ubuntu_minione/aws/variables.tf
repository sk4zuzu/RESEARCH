variable "region" {
  type = string
}

variable "env_name" {
  type = string
}

variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "ubuntu_version" {
  type    = string
  default = "focal-20.04-amd64-server"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "volume_size" {
  type    = number
  default = 160
}

variable "destroy" {
  type    = bool
  default = false
}

variable "allowed" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "key" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}
