
locals {
  private_subnets = [ var.master_cidr_block, var.compute_cidr_block ]
}

resource "random_id" "sg" {
  prefix      = "${var.env_name}-sg-"
  byte_length = 4
}

resource "aws_security_group" "sg-master" {
  name   = "${random_id.sg.hex}-master"
  tags   = { Name = "${random_id.sg.hex}-master" }
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ var.SG_ALLOWED_ADDRESS ]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.private_subnets
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

resource "aws_security_group" "sg-compute" {
  name   = "${random_id.sg.hex}-compute"
  tags   = { Name = "${random_id.sg.hex}-compute" }
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.private_subnets
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

# vim:ts=2:sw=2:et:syn=terraform:
