resource "random_id" "epicli" {
  prefix      = "${var.env_name}-epicli-"
  byte_length = 4
}
