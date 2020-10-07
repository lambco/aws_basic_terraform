//chapter2

provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_vpc" "vpc_zone" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "VPC領域"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc_zone.id
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc_zone.id
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.vpc_zone.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"

  tags = {
    Name = "パブリックサブネット"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc_zone.id
  tags = {
    Name = "パブリックルートテーブル"
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.gateway.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
