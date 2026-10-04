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
# Get VPC
# --------------------------------------------------

data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["vcs-vpc"]
  }
}

# --------------------------------------------------
# Get Public Subnet
# --------------------------------------------------

data "aws_subnet" "public_1" {
  filter {
    name   = "tag:Name"
    values = ["public-subnet-1"]
  }

  vpc_id = data.aws_vpc.main.id
}

# --------------------------------------------------
# Get Private Subnet
# --------------------------------------------------

data "aws_subnet" "private_1" {
  filter {
    name   = "tag:Name"
    values = ["private-subnet-1"]
  }

  vpc_id = data.aws_vpc.main.id
}

# --------------------------------------------------
# Get Jump Host Security Group
# --------------------------------------------------

data "aws_security_group" "jump_host" {
  filter {
    name   = "tag:Name"
    values = ["jump-host-sg"]
  }

  vpc_id = data.aws_vpc.main.id
}

# --------------------------------------------------
# Get Private EC2 Security Group
# --------------------------------------------------

data "aws_security_group" "private_ec2" {
  filter {
    name   = "tag:Name"
    values = ["private-ec2-sg"]
  }

  vpc_id = data.aws_vpc.main.id
}

# --------------------------------------------------
# Amazon Linux 2023 AMI
# --------------------------------------------------

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --------------------------------------------------
# Public EC2 - Jump Host
# --------------------------------------------------

resource "aws_instance" "jump_host" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  subnet_id = data.aws_subnet.public_1.id

  vpc_security_group_ids = [
    data.aws_security_group.jump_host.id
  ]

  key_name = var.key_name

  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "jump-host"
    Role = "jump-host"
  }
}

# --------------------------------------------------
# Private EC2
# --------------------------------------------------

resource "aws_instance" "private_ec2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  subnet_id = data.aws_subnet.private_1.id

  vpc_security_group_ids = [
    data.aws_security_group.private_ec2.id
  ]

  key_name = var.key_name

  # IMPORTANT:
  # No public IP
  associate_public_ip_address = false

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "private-ec2"
    Role = "private"
  }
}