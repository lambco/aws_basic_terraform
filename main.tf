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

resource "aws_eip" "nat_gateway" {
  vpc     = true
  depends_on = [aws_internet_gateway.gateway]
}

resource "aws_nat_gateway" "gateway" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.public.id
  depends_on    = [aws_internet_gateway.gateway]
}


resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  nat_gateway_id         = aws_nat_gateway.gateway.id
  destination_cidr_block = "0.0.0.0/0"
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


resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.vpc_zone.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "プライベートサブネット"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc_zone.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# AMI Profile

data "aws_ami" "al2_latest" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "block-device-mapping.volume-type"
    values = ["gp2"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}


#Security Group

resource "aws_security_group" "web_sg" {
  name   = "WEB-SG"
  vpc_id = "${aws_vpc.vpc_zone.id}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.al2_latest.image_id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  subnet_id              = aws_subnet.public.id
  key_name               = aws_key_pair.my_key.id
  instance_type          = "t2.micro"
  private_ip             = "10.0.1.10"
  tags = {
    Name = "WEBサーバー"
  }
}

resource "aws_security_group" "db_sg" {
  name   = "DB-SG"
  vpc_id = aws_vpc.vpc_zone.id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "db_server" {
  ami                         = data.aws_ami.al2_latest.image_id
  vpc_security_group_ids      = [aws_security_group.db_sg.id]
  subnet_id                   = aws_subnet.private.id
  key_name                    = aws_key_pair.my_key.id
  instance_type               = "t2.micro"
  private_ip                  = "10.0.2.10"
  associate_public_ip_address = false
  tags = {
    Name = "DBサーバー"
  }
}

resource "aws_key_pair" "my_key" {
  key_name   = "my-key"
  public_key = file("./my-key.pub")
}
