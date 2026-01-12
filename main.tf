
# ====== AMI Lookup via SSM Parameter (region-aware) ======
# Choose one of these SSM parameters based on architecture:
# - Amazon Linux 2023 x86_64: /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64
# - Amazon Linux 2023 ARM64 : /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64
# - Amazon Linux 2   x86_64 : /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2
# - Amazon Linux 2   ARM64 : /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-arm64-gp2

# Pick parameter automatically based on instance type naming (simple heuristic).
# If instance_type starts with "t4g", "m6g", "c6g", "r6g" -> ARM; else x86_64.
locals {
  is_arm = can(regex("^t4g|^m6g|^c6g|^r6g", var.instance_type))
  ssm_param = local.is_arm
    ? "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
    : "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "aws_ssm_parameter" "al_ami" {
  name = local.ssm_param
}

# ====== Networking: Security Group for SSH ======
resource "aws_security_group" "ssh" {
  name        = "${var.aws_ec2}-sg"
  description = "Allow SSH ingress"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from allowed CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_ingress_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.aws_ec2}-sg"
    Project = var.aws_ec2
  }
}

# Grab the default VPC & a public subnet to keep the sample simple
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ====== Optional Key Pair (only if you passed a public key) ======
resource "aws_key_pair" "this" {
  count      = length(trimspace(var.public_key_openssh)) > 0 ? 1 : 0
  key_name   = var.vm-keypair
  public_key = var.public_key_openssh
}

# ====== EC2 Instance ======
resource "aws_instance" "this" {
  ami                         = data.aws_ssm_parameter.al_ami.value
  instance_type               = var.instance_type

  # If user didn't provide a key, EC2 still launches but you won't be able to SSH with a key.
  key_name = length(aws_key_pair.this) > 0 ? aws_key_pair.this[0].key_name : null

  subnet_id                   = element(data.aws_subnets.default_public.ids, 0)
  vpc_security_group_ids      = [aws_security_group.ssh.id]
  associate_public_ip_address = true

  user_data = <<-EOT
              #!/bin/bash
              yum -y update || dnf -y update
              # Simple proof it's alive
              echo "Hello from Terraform at $(date)" > /etc/motd
              EOT

  tags = {
    Name    = "${var.aws-ec2}-ec2"
    Project = var.aws-ec2
  }
}
