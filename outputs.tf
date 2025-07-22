output "public_ip" {
    description = "The public IP address of the EC2 instance"
    value = aws_instance.web_server.public_ip
}

output "vpc_id" {
    description = "The ID of the VPC"
    value = aws_vpc.main.id
}