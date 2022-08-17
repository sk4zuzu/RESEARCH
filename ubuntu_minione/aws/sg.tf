resource "aws_security_group" "self" {
  name = random_id.self.hex

  vpc_id = aws_vpc.self.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.allowed
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = random_id.self.hex
  }
}
