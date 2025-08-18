resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "test-vpc" }
}

resource "aws_subnet" "subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_a_cidr
  availability_zone       = var.availability_zone_a
  map_public_ip_on_launch = true
  tags = { Name = "subnet-a" }
}

resource "aws_subnet" "subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_b_cidr
  availability_zone       = var.availability_zone_b
  map_public_ip_on_launch = true
  tags = { Name = "subnet-b" }
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound and outbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "test_a" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet_a.id
  associate_public_ip_address = true
  key_name                    = var.private_key
  vpc_security_group_ids      = [aws_security_group.allow_all.id]
  tags = { Name = "test-ec2-a" }
}

resource "aws_instance" "test_b" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet_b.id
  associate_public_ip_address = true
  key_name                    = var.private_key
  vpc_security_group_ids      = [aws_security_group.allow_all.id]
  tags = { Name = "test-ec2-b" }
}