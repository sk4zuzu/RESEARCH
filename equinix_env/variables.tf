variable "auth_token" {
  type = string
}

variable "project_id" {
  type = string
}

variable "hosts" {
  type = map(object({
    plan             = string
    metro            = string
    operating_system = string
  }))
}
