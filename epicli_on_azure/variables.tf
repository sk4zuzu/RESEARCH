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

variable "size" {
  type    = string
  default = "Standard_A1_v2"
}

variable "disk_size_gb" {
  type    = string
  default = "64"
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
    offer     = "0001-com-ubuntu-minimal-focal-daily"
    sku       = "minimal-20_04-daily-lts"
    version   = "20.04.202011030"
  }
}
