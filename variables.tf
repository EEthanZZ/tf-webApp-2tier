variable "region" {
  type        = string
  default     = "us-east-2"
  description = "AWS region"
}

variable "availability_zone_1" {
  type        = string
  default     = "us-east-2a"
  description = "Availability Zone 1"
}

variable "availability_zone_2" {
  type        = string
  default     = "us-east-2b"
  description = "Availability Zone 2"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_1" {
  description = "The CIDR block for public subnet 1 of 2"
  default     = "10.0.1.0/24"
}

variable "public_subnet_cidr_2" {
  description = "The CIDR block for public subnet 2 of 2"
  default     = "10.0.2.0/24"
}

variable "private_subnet_cidr_1" {
  description = "The CIDR block for private subnet 1 of 2"
  default     = "10.0.3.0/24"
}

variable "private_subnet_cidr_2" {
  description = "The CIDR block for private subnet 2 of 2"
  default     = "10.0.4.0/24"
}