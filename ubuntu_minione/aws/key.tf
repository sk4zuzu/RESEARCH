resource "aws_key_pair" "self" {
  key_name   = random_id.self.hex
  public_key = file(var.key)

  tags = {
    Name = random_id.self.hex
  }
}
