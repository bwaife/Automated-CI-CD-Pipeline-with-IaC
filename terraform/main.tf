# ------------------------------
# Terraform Configuration Block
# ------------------------------

# Tell Terraform which version to use and what providers (plugins) are needed.
terraform {
  required_version = ">= 1.0" # Terraform version must be at least 1.0
  required_providers {
    aws = {
      source  = "hashicorp/aws" # Use the official AWS provider from HashiCorp
      version = "~> 5.0"        # Use any 5.x version (e.g., 5.1, 5.2)
    }
  } 
  backend "s3" {
    bucket = "mybucket-bw" # S3 bucket to store Terraform state files
    key    = "terraform.tfstate" # Path within the bucket
    region = "eu-west-1" # AWS region where the S3 bucket is located
    
  }
}

resource "null_resource" "ansible" {
  triggers = {
    instance_ip = aws_instance.web_server.public_ip # Trigger this resource when the instance IP changes
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i inventory.ini playbook.yml"    
  }
  
}

# ------------------------------
# AWS Provider Block
# ------------------------------

# This block connects Terraform to your AWS account and sets default tags.
provider "aws" {
  region = "eu-west-1"  # The AWS region where all resources will be created

  default_tags {
    tags = {
      Project     = "Automated-CI-CD-Pipeline-with-IaC"  # Name of your project
      Environment = "dev"                                # Environment type (dev/test/prod)
      Owner       = "Ben"                                # Who owns this infrastructure
      ManagedBy   = "Terraform"                          # Indicating this is managed using Terraform
    }
  }
}

# ------------------------------
# Data Sources (Read-Only Info)
# ------------------------------

# Find the latest Amazon Linux 2 AMI image ID
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]  # Official Amazon AMIs only

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]  # Match Amazon Linux 2 AMI
  }
}

# Get a list of available Availability Zones in the selected region
data "aws_availability_zones" "available" {
  state = "available"
}

# ------------------------------
# VPC (Virtual Private Cloud)
# ------------------------------

# Create a virtual network (VPC) to isolate your resources
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr           # IP address range for your VPC
  enable_dns_hostnames = true                   # Enable DNS hostnames (helpful for instances)
  enable_dns_support   = true                   # Enable DNS support
  tags = {
    Name = "CICD-VPC"  # Resource name tag
  }
}

# ------------------------------
# Subnet (Public)
# ------------------------------

# Create a subnet inside the VPC, where public resources will live
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.aws_region}a"  # Use one AZ
  map_public_ip_on_launch = true                 # Automatically assign public IP to instances
  tags = {
    Name = "Public-Subnet"
  }
}

# ------------------------------
# Internet Gateway
# ------------------------------

# Allows traffic from the VPC to the internet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "CICD-Internet-Gateway"
  }
}

# ------------------------------
# Route Table and Association
# ------------------------------

# Route table for public internet access
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"                  # Route all traffic
    gateway_id = aws_internet_gateway.gw.id  # To the Internet Gateway
  }

  tags = {
    Name = "Public-Route-Table"
  }
}

# Link the subnet with the route table so traffic can leave the VPC
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ------------------------------
# Security Group (Firewall)
# ------------------------------

# Control which traffic can reach your EC2 instance
resource "aws_security_group" "public_sg" {
  name        = "Public-SG"
  description = "Allow HTTP and SSH access"
  vpc_id      = aws_vpc.main.id

  # Allow SSH (port 22) from anywhere - used to connect via terminal
  ingress {
    description = "Allow SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # ⚠️ Insecure - open to the world (ok for testing only)
  }

  # Allow HTTP (port 80) from anywhere - used for web traffic
  ingress {
    description = "Allow HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow ALL outbound traffic (EC2 to Internet)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Public-Security-Group"
  }
}

# ------------------------------
# EC2 Instance (Web Server)
# ------------------------------

# Launch a virtual machine (EC2 instance) in the public subnet
resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.amazon_linux.id # Use the latest Amazon Linux 2 AMI
  instance_type               = var.instance_type             # e.g., t2.micro
  subnet_id                   = aws_subnet.public.id          # Place it in the public subnet
  vpc_security_group_ids      = [aws_security_group.public_sg.id]  # Apply the security group
  associate_public_ip_address = true                          # Assign public IP for external access
  key_name                    = var.key_pair_name             # Use your SSH key pair

  tags = {
    Name        = "${var.project_name}-Web-Server"  # Name includes your project name
    Environment = var.environment                   # dev, test, or prod
  }
}
