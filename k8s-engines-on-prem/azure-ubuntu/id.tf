resource "random_id" "azure-ubuntu" {
  prefix      = "${var.env_name}-azure-ubuntu-"
  byte_length = 4
}
