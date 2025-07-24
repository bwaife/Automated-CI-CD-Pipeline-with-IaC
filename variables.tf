# ------------------------------
# AWS Configuration
# ------------------------------

# The AWS region (geographic location) where your resources will be created.
# Example: us-west-2 = Oregon, us-east-1 = N. Virginia
variable "aws_region" {
  description = "The AWS region where resources will be created"
  default     = "us-west-2"
}

# ------------------------------
# EC2 Instance Configuration
# ------------------------------

# The type of virtual machine (EC2 instance) you want to create.
# t2.micro is small and free-tier eligible for testing.
variable "instance_type" {
  description = "The type of EC2 instance to create"
  type        = string
  default     = "t2.micro"
}

# ------------------------------
# Networking Configuration
# ------------------------------

# The IP range for your virtual private cloud (VPC).
# This creates a private network to isolate your cloud resources.
# Format must be in CIDR notation.
variable "vpc_cidr" {
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

# The IP range for your public subnet.
# This allows your EC2 instance to access the internet.
# Must be a subset of the VPC CIDR.
variable "public_subnet_cidr" {
  description = "Public subnet CIDR block"
  default     = "10.0.1.0/24"
}


# The name of the SSH key pair used to securely connect to your EC2 instance.
# You must create or download this key pair from the AWS Console.
variable "key_pair_name" {
  description = "The name of the SSH key pair to use for the EC2 instance"
  default     = "my-key-pair"
}


# The main project name used for naming and tagging your resources.
# Tags help you organize and manage AWS resources.
# Only letters, numbers, and hyphens are allowed.
variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "devops-project"

  # Ensures the project name is valid (only a-z, A-Z, 0-9, and hyphens)
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.project_name))
    error_message = "Project name must consist of alphanumeric characters and hyphens only."
  }
}

variable "environment" {
    description = "Enviroment name (e.g., dev, staging, prod)"
    type        = string
    default     = "dev"
  
    validation {
        condition = contains(["dev", "staging", "prod"], var.environment)
        error_message = "Environment must be one of: dev, staging, prod."
    }
}
