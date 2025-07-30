# ==========================
# Key Pair (Auto-created)
# ==========================
# resource "aws_key_pair" "deployed_key" {
#   key_name   = "kkdevops-key-${timestamp()}"       # Unique key name with timestamp
#   public_key = var.public_key        # Path to your local public key (.pub)
# }
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
###EC2 Instances Configuration
# ==========================    
# ========================== 

resource "aws_instance" "master" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet_a.id
  private_ip             = "192.168.1.5"
  key_name               = var.private_key
  vpc_security_group_ids = [aws_security_group.demo.id]
  associate_public_ip_address = true

  # connection {
  #   type        = "ssh"
  #   user        = "ubuntu"
  #   private_key = file(var.private_key_path)
  #   host        = self.public_ip
  #   timeout     = "2m" # Increased timeout for connection
  # }

  # provisioner "file" {
  #   source      = "${path.module}/kube_cluster.sh"
  #   destination = "/home/ubuntu/kube_cluster.sh"
   # }

  # provisioner "remote-exec" {
  #   inline = [
  #     "chmod +x /home/ubuntu/kube_cluster.sh",
  #     "sudo MASTER_PRIVATE_IP=192.168.1.5 bash /home/ubuntu/kube_cluster.sh"
  #   ]
  # }

  tags = { Name = "master-node" }
}

resource "aws_instance" "slave" {
  count                  = 3
  ami                    = var.ami_id
  instance_type          = var.instance_type
  # Using the same AMI ID and instance type as the master node
  subnet_id              = aws_subnet.subnet_b.id
  private_ip             = "192.168.2.${count.index + 5}"
  key_name               = var.private_key
  vpc_security_group_ids = [aws_security_group.demo.id]
  associate_public_ip_address = true

  # connection {
  #   type        = "ssh"
  #   user        = "ubuntu"
  #   private_key = file(var.private_key_path)
  #   host        = self.public_ip
  #   timeout     = "2m" # Increased timeout for connection
  # }

  # provisioner "file" {
  #   source      = "${path.module}/kube_cluster.sh"
  #   destination = "/home/ubuntu/kube_cluster.sh"
  # }

  # provisioner "remote-exec" {
  #   inline = [
  #     "chmod +x /home/ubuntu/kube_cluster.sh",
  #     "sudo MASTER_PRIVATE_IP=192.168.1.5 bash /home/ubuntu/kube_cluster.sh"
  #   ]
  # }

  depends_on = [aws_instance.master]
  tags       = { Name = "slave-node-${count.index + 1}" }
}
