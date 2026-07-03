###############################################################################
# AWS VPC Module – main.tf
# Creates: VPC, public/private subnets, IGW, NAT Gateway, route tables
###############################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  az_count              = length(var.availability_zones)
  nat_gateway_count     = var.single_nat_gateway ? 1 : local.az_count
  public_subnet_count   = length(var.public_subnet_cidrs)
  private_subnet_count  = length(var.private_subnet_cidrs)
}

###############################################################################
# VPC
###############################################################################

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = var.vpc_name })
}

###############################################################################
# Internet Gateway
###############################################################################

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.vpc_name}-igw" })
}

###############################################################################
# Public Subnets
###############################################################################

resource "aws_subnet" "public" {
  count = local.public_subnet_count

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index % local.az_count]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name                     = "${var.vpc_name}-public-${count.index + 1}"
    "kubernetes.io/role/elb" = "1"
  })
}

###############################################################################
# Private Subnets
###############################################################################

resource "aws_subnet" "private" {
  count = local.private_subnet_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index % local.az_count]

  tags = merge(var.tags, {
    Name                              = "${var.vpc_name}-private-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

###############################################################################
# Elastic IPs for NAT Gateways
###############################################################################

resource "aws_eip" "nat" {
  count  = local.nat_gateway_count
  domain = "vpc"

  tags = merge(var.tags, { Name = "${var.vpc_name}-nat-eip-${count.index + 1}" })

  depends_on = [aws_internet_gateway.this]
}

###############################################################################
# NAT Gateways
###############################################################################

resource "aws_nat_gateway" "this" {
  count = local.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, { Name = "${var.vpc_name}-nat-${count.index + 1}" })

  depends_on = [aws_internet_gateway.this]
}

###############################################################################
# Public Route Table
###############################################################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, { Name = "${var.vpc_name}-public-rt" })
}

resource "aws_route_table_association" "public" {
  count = local.public_subnet_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

###############################################################################
# Private Route Tables
###############################################################################

resource "aws_route_table" "private" {
  count  = local.nat_gateway_count
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index].id
  }

  tags = merge(var.tags, { Name = "${var.vpc_name}-private-rt-${count.index + 1}" })
}

resource "aws_route_table_association" "private" {
  count = local.private_subnet_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[var.single_nat_gateway ? 0 : count.index % local.nat_gateway_count].id
}
