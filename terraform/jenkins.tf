# ------------------------------
# Jenkins Security Group
# ------------------------------
resource "aws_security_group" "jenkins_sg" {
  name = "Jenkins-SG"
  description = "Allow Jenkins web interface and SSH access"
  vpc_id = aws_vpc.main.id

tags = {
  Name = "Jenkins-Security-Group"
}

}

#SSH access rule 
resource "aws_security_group_rule" "jenkins_ssh" {
  type = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["93.107.64.147/32"]  # Open to the world (ok for testing only)
  description       = "SSH access restricted to admin IP only"
  security_group_id = aws_security_group.jenkins_sg.id
}

resource "aws_security_group_rule" "jenkins_web_interface" {
  type = "ingress"
  from_port   = 8080
  to_port     = 8080
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]  # Open to the world (ok for testing only)
  security_group_id = aws_security_group.jenkins_sg.id
  
}

resource "aws_security_group_rule" "jenkins_egress" {
  type = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"  # -1 means all protocols
  cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  security_group_id = aws_security_group.jenkins_sg.id
}

# -----------------------------
# Jenkins EC2 Instance
# ------------------------------

resource "aws_instance" "Jenkins_server" {
  ami = data.aws_ami.amazon_linux.id # Use the latest Amazon Linux 2 AMI
  instance_type = "t2.medium" # Use a larger instance type for Jenkins
  subnet_id = aws_subnet.public.id # Place it in the public subnet
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id] 
  associate_public_ip_address = true # Assign public IP for external access
  key_name = var.key_pair_name # Use your SSH key pair

  #Storage for Jenkins data
  root_block_device {
    volume_size = 20 # 20 GB for Jenkins data
    volume_type = "gp3" # General Purpose SSD
  }

  tags = {
     Name = "${var.project_name}-Jenkins-Server" # Name includes your project name
      Environment = var.environment # dev, test, or prod
  }
}


# ------------------------------
# Jenkins Ansible Configuration
# ------------------------------

resource "null_resource" "Jenkins_ansible" {
  triggers = {
    instance_ip = aws_instance.Jenkins_server.public_ip # Trigger this resource when the instance IP changes
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i ../ansible/inventory.ini ../ansible/playbook.yml"
  }

  depends_on = [ aws_instance.Jenkins_server ]
  
}

# ------------------------------
# Outputs for Jenkins
# ------------------------------

output "jenkins_url" {
    value = "https://${aws_instance.Jenkins_server.public_ip}:8080"
    description = "The URL to access Jenkins"
}

output "jenkins_ssh_command" {
    value = "ssh -i ${var.key_pair_name}.pem ec2-user@${aws_instance.Jenkins_server.public_ip}"
    description = "SSH command to connect to the Jenkins server"
}

output "web_server_url" {
    value = "http://${aws_instance.web_server.public_ip}"
    description = "The URL to access the web server"

}
