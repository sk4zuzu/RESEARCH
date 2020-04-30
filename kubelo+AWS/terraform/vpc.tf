
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

resource "aws_eip" "vpc" {
  depends_on = [ aws_internet_gateway.vpc ]
  tags       = { Name = random_id.vpc.hex }
  vpc        = true
}

resource "aws_subnet" "vpc-public" {
  tags       = { Name = "${random_id.vpc.hex}-public" }
  cidr_block = var.master_cidr_block
  vpc_id     = aws_vpc.vpc.id
}

resource "aws_nat_gateway" "vpc" {
  depends_on    = [ aws_internet_gateway.vpc ]
  tags          = { Name = random_id.vpc.hex }
  allocation_id = aws_eip.vpc.id
  subnet_id     = aws_subnet.vpc-public.id
}

resource "aws_subnet" "vpc-private" {
  tags       = { Name = "${random_id.vpc.hex}-private" }
  cidr_block = var.compute_cidr_block
  vpc_id     = aws_vpc.vpc.id
}

resource "aws_route_table" "vpc-public" {
  tags   = { Name = "${random_id.vpc.hex}-public" }
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc.id
  }
}

resource "aws_route_table_association" "vpc-public" {
  subnet_id      = aws_subnet.vpc-public.id
  route_table_id = aws_route_table.vpc-public.id
}

resource "aws_route_table" "vpc-private" {
  tags   = { Name = "${random_id.vpc.hex}-private" }
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.vpc.id
  }
}

resource "aws_route_table_association" "vpc-private" {
  subnet_id      = aws_subnet.vpc-private.id
  route_table_id = aws_route_table.vpc-private.id
}

# vim:ts=2:sw=2:et:syn=terraform:
