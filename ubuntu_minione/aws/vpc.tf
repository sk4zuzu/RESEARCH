resource "aws_vpc" "self" {
  cidr_block = var.cidr_block

  instance_tenancy = "default"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = random_id.self.hex
  }
}

resource "aws_internet_gateway" "self" {
  vpc_id = aws_vpc.self.id

  tags = {
    Name = random_id.self.hex
  }
}

resource "aws_subnet" "self" {
  vpc_id = aws_vpc.self.id

  cidr_block = cidrsubnet(var.cidr_block, 8, 240)  # 10.0.240.0/24

  tags = {
    Name = random_id.self.hex
  }
}

resource "aws_route_table" "self" {
  vpc_id = aws_vpc.self.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.self.id
  }

  tags = {
    Name = random_id.self.hex
  }
}

resource "aws_route_table_association" "self" {
  subnet_id      = aws_subnet.self.id
  route_table_id = aws_route_table.self.id
}
