
# AWS Provider Configuration for Terraform

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  } 
}

provider "aws" {
    region = "us-west-2"
    default_tags {
        tags = {
          Project = "Automated-CI-CD-Pipeline-with-IaC"
          Environment = "dev"
            Owner = "Ben"
            ManagedBy = "Terraform"

        }
      
    }
  
}

# Data Sources
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
}

data "aws_availability_zones" "available" {
    state = "available"
}


# VPC Configuration
  resource "aws_vpc" "main" {
    cidr_block           =  var.vpc_cidr  
    enable_dns_hostnames = true
    enable_dns_support   = true
    tags = {
      Name = "CICD-VPC"
    }
  }

  # Subnet Configuration
  resource "aws_subnet" "public" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_cidr
    availability_zone = "${var.aws_region}a"
    map_public_ip_on_launch = true
    tags = {
      Name = "Public-Subnet"
  }
  }

  # Create Internet Gateway
  resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.main.id
    tags = {
      Name = "CICD-Internet-Gateway"
    }
  }

  # Create a Route Table
    resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.gw.id
    }
    tags = {
      Name = "Public-Route-Table"
    }
  }

    # Associate Route Table with Subnet
resource "aws_route_table_association" "public" {
      subnet_id      = aws_subnet.public.id
      route_table_id = aws_route_table.public.id
    }

# Security Group Configuration
resource "aws_security_group" "public_sg" {
    name        = "Public-SG"
    description = "Allow HTTP and SSH access"
    vpc_id      = aws_vpc.main.id

    ingress {
        description = "Allow SSH access"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # Warning Restrict this in production
    }

    ingress {
        description = "Allow HTTP access"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # Warning Restrict this in production
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
    }

    tags = {
        Name = "Public-Security-Group"
    }
}

# EC2 Instance Configuration
resource "aws_instance" "web_server" {
    # Basic configuration for the EC2 instance
    # Amazon Linux 2 AMI
    ami = data.aws_ami.amazon_linux.id
    instance_type = var.instance_type

    # Network configuration
    subnet_id = aws_subnet.public.id
    vpc_security_group_ids = [aws_security_group.public_sg.id]

    #SSH Access
    key_name = var.key_pair_name

    tags = {
        Name = "Web-Server"
    }

}


    
