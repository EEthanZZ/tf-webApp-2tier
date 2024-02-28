variable "region" {
  type        = string
  default     = "us-east-2"
  description = "AWS region"
}

variable "availability_zones" {
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
  description = "List of Availability Zones"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "The CIDR blocks for public subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "The CIDR blocks for private subnets"
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "instance_type" {
  default     = "t2.micro"
}

variable "auto_scaling_group" {
  description = "Auto Scaling Group configuration"
  default = {
    min_size          = 2
    max_size          = 5
    desired_capacity  = 2
  }
}

variable ingressRule {
  type        = list(number)
  default     = [80, 443]
  description = "description"
}
variable egressRule {
  type        = list(number)
  default     = [80, 443]
  description = "description"
}