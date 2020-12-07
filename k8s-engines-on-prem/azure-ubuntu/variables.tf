variable "location" {
  type = string
}

variable "env_name" {
  type = string
}

variable "address_space" {
  type    = string
  default = "10.0.0.0/16"
}

variable "_count" {
  type    = number
  default = 6
}

variable "size" {
  type    = string
  default = "Standard_DS2_v2"
}

variable "disk_size_gb" {
  type    = string
  default = "30"
}

variable "source_image_reference" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

variable "public_key_path" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}

variable "install_docker" {
  type    = bool
  default = true
}
