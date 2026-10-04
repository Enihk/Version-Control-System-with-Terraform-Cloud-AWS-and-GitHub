terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --------------------------------------------------
# Find existing VPC created by network branch
# --------------------------------------------------

data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["vcs-vpc"]
  }
}

# --------------------------------------------------
# Jump Host Security Group
# --------------------------------------------------

resource "aws_security_group" "jump_host" {
  name        = "jump-host-sg"
  description = "Security group for public jump host"
  vpc_id      = data.aws_vpc.main.id

  # SSH from trusted administrator IP only
  ingress {
    description = "SSH from administrator"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  # Allow outbound traffic
  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jump-host-sg"
  }
}

# --------------------------------------------------
# Private EC2 Security Group
# --------------------------------------------------

resource "aws_security_group" "private_ec2" {
  name        = "private-ec2-sg"
  description = "Security group for private EC2"
  vpc_id      = data.aws_vpc.main.id

  # ------------------------------------------------
  # SSH ONLY FROM JUMP HOST
  # ------------------------------------------------

  ingress {
    description     = "SSH from jump host only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jump_host.id]
  }

  # Outbound traffic goes through NAT Gateway
  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-ec2-sg"
  }
}