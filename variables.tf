variable "aws_region" {
    description = "The AWS region where resources will be created"
    default     = "us-west-2"
}

variable "instance_type" {
    description = "The type of EC2 instance to create"
    default     = "t2.micro"
}

variable "vpc_cidr" {
    description = "VPC CIDR block"
    default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
    description = "Public subnet CIDR block"
    default     = "10.0.1.0/24"
}

variable "key_pair_name" {
    description = "The name of the SSH key pair to use for the EC2 instance"
    default     = "my-key-pair"
}