terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "local" {}
}

provider "aws" {
  region = var.region
}

# Get current workspace
locals {
  workspace_name = terraform.workspace
  env_config     = var.environment_config[local.workspace_name]
  
  # Common naming convention
  instance_name = "${local.env_config.instance_name_prefix}-${random_id.instance_suffix.hex}"
}

# Random suffix for unique resource names
resource "random_id" "instance_suffix" {
  byte_length = 4
}

# Security Group
resource "aws_security_group" "react_app" {
  name        = "sg-${local.workspace_name}-react-app"
  description = "Security group for React app EC2 instance"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.env_config.tags, {
    Name = "sg-${local.workspace_name}-react-app"
  })

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.env_config.tags, {
    Name = "vpc-${local.workspace_name}-react-app"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.env_config.tags, {
    Name = "igw-${local.workspace_name}-react-app"
  })
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = merge(local.env_config.tags, {
    Name = "subnet-${local.workspace_name}-public"
  })
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.env_config.tags, {
    Name = "rt-${local.workspace_name}-public"
  })
}

# Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "role-${local.workspace_name}-ec2-react-app"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.env_config.tags
}

# IAM Role Policy Attachment
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "profile-${local.workspace_name}-ec2-react-app"
  role = aws_iam_role.ec2_role.name
}

# Key Pair (using existing or create new)
resource "aws_key_pair" "react_app" {
  key_name   = "key-${local.workspace_name}-react-app"
  public_key = var.ssh_public_key

  tags = local.env_config.tags
}

# EC2 Instance
resource "aws_instance" "react_app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.react_app.key_name
  vpc_security_group_ids = [aws_security_group.react_app.id]
  subnet_id              = aws_subnet.public.id
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = base64encode(templatefile("${path.module}/scripts/deploy-react-app.sh", {
    environment = local.workspace_name
  }))

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = merge(local.env_config.tags, {
    Name = local.instance_name
  })

  depends_on = [aws_internet_gateway.main]
}

# Elastic IP
resource "aws_eip" "react_app" {
  instance = aws_instance.react_app.id
  domain   = "vpc"

  tags = merge(local.env_config.tags, {
    Name = "eip-${local.workspace_name}-react-app"
  })
}

# Get latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}