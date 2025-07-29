variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
}

variable "private_key_path" {
  description = "Name of the key pair to use for EC2 instances"
  type        = string
  default     = "kk1"
}

variable "vpc_id" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "192.168.0.0/16"
}

variable "subnet_a_cidr" {
  description = "CIDR block for Subnet A (master node)"
  type        = string
  default     = "192.168.1.0/24"
}

variable "subnet_b_cidr" {
  description = "CIDR block for Subnet B (slave nodes)"
  type        = string
  default     = "192.168.2.0/24"
}

variable "availability_zone_a" {
  description = "Availability zone for Subnet A"
  type        = string
  default     = "us-east-1a"
}

variable "availability_zone_b" {
  description = "Availability zone for Subnet B"
  type        = string
  default     = "us-east-1b"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-020cba7c55df1f615" # Example AMI ID, replace with a valid one for your region
}

variable "instance_type" {
  description = "Instance type for master node"
  type        = string
  default     = "t2.medium"
}