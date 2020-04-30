
resource "random_id" "vpc" {
  prefix      = "${var.env_name}-vpc-"
  byte_length = 4
}

resource "aws_vpc" "vpc" {
  tags                 = { Name = random_id.vpc.hex }
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "vpc" {
  tags   = { Name = random_id.vpc.hex }
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "vpc" {
  tags   = { Name = random_id.vpc.hex }
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc.id
  }
}

resource "aws_subnet" "vpc-master" {
  tags       = { Name = "${random_id.vpc.hex}-master" }
  cidr_block = var.master_cidr_block
  vpc_id     = aws_vpc.vpc.id
}

resource "aws_subnet" "vpc-compute" {
  tags       = { Name = "${random_id.vpc.hex}-compute" }
  cidr_block = var.compute_cidr_block
  vpc_id     = aws_vpc.vpc.id
}

resource "aws_route_table_association" "vpc-master" {
  subnet_id      = aws_subnet.vpc-master.id
  route_table_id = aws_route_table.vpc.id
}

resource "aws_route_table_association" "vpc-compute" {
  subnet_id      = aws_subnet.vpc-compute.id
  route_table_id = aws_route_table.vpc.id
}

# vim:ts=2:sw=2:et:syn=terraform:
