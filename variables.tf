variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "admin_cidr" {
  description = "Your trusted public IP address in CIDR notation"
  type        = string
}

