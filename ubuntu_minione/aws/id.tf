resource "random_id" "self" {
  prefix      = "${var.env_name}-"
  byte_length = 4
}
