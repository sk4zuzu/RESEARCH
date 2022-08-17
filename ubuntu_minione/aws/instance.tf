resource "aws_instance" "self" {
  count = var.destroy ? 0 : 1

  lifecycle {
    ignore_changes = [ami]
  }

  ami           = data.aws_ami.self.id
  instance_type = var.instance_type

  key_name = aws_key_pair.self.key_name

  subnet_id              = aws_subnet.self.id
  vpc_security_group_ids = [aws_security_group.self.id]

  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = var.volume_size

    delete_on_termination = true
    encrypted             = false
  }

  tags = {
    Name = random_id.self.hex
  }
}
