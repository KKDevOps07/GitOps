# ==========================
# Variable Declarations
# ==========================

# ==========================
# VPC Configuration
# ==========================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_id
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "KKDevOps07-vpc"
  }
}

# ==========================
# Subnet Configuration
# ==========================
resource "aws_subnet" "subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_a_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone_a
  tags = {
    Name = "subnet-a"
  }
}

resource "aws_subnet" "subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_b_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone_b
  tags = {
    Name = "subnet-b"
  }
}

# ==========================
# Internet Gateway
# ==========================
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "KKDevOps07-igw"
  }
}

# ==========================
# Route Table (Public)
# ==========================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "KKDevOps07-public-rt"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.public.id
}

# ==========================
# Security Group (Allow all HTTP/HTTPS/SSH)
# ==========================
resource "aws_security_group" "demo" {
  vpc_id = aws_vpc.main.id

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
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "demo-sg"
  }
}

# ==========================
# ALB Security Group
# ==========================
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

# ==========================
# Kubernetes Cluster Security Group
# ==========================
resource "aws_security_group" "k8s_cluster_sg" {
  vpc_id = aws_vpc.main.id

  # Allow all traffic within the security group (for cluster communication)
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    self            = true
  }

  # Allow Kubernetes API server access (default 6443)
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH access
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

  tags = {
    Name = "k8s-cluster-sg"
  }
}

# ==========================
# Redis Security Group
# ==========================
resource "aws_security_group" "redis_sg" {
  vpc_id = aws_vpc.main.id

  # Allow Redis port (6379) from within the VPC
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "redis-sg"
  }
}

# ==========================
# Application Load Balancer
# ==========================
resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]

  tags = {
    Name = "app-lb"
  }
}

# ==========================
# Target Group
# ==========================
resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "app-tg"
  }
}

# ==========================
# Register EC2 Instances with Target Group
# ==========================
resource "aws_lb_target_group_attachment" "master" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.master.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "slaves" {
  count            = 3
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.slave[count.index].id
  port             = 80
}

# ==========================
# Listener
# ==========================
resource "aws_lb_listener" "app_lb_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# ==========================
# EC2 Instances
# ==========================
resource "aws_instance" "master" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  availability_zone      = var.availability_zone_a
  key_name               = var.private_key_path
  subnet_id              = aws_subnet.subnet_a.id
  private_ip             = "192.168.1.5" # Use a valid, non-reserved IP in subnet_a
  vpc_security_group_ids = [aws_security_group.demo.id]
  associate_public_ip_address = true
  user_data              = file("${path.module}/kub.sh")
  tags = {
    Name = "master-node"
  }
}

resource "aws_instance" "slave" {
  count                  = 3
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  key_name               = var.private_key_path
  availability_zone      = var.availability_zone_b
  subnet_id              = aws_subnet.subnet_b.id
  private_ip             = "192.168.2.${count.index + 5}" # Use valid, non-reserved IPs in subnet_b
  vpc_security_group_ids = [aws_security_group.demo.id]
  associate_public_ip_address = true
  user_data              = file("${path.module}/kub.sh")
  tags = {
    Name = "slave-node-${count.index + 1}"
  }
}