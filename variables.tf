

variable "region" {
  type        = string
  default     = "us-west-2"
  description = "AWS region"
}

# available zones
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
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
  default = "t2.micro"
}

variable "auto_scaling_group" {
  description = "Auto Scaling Group configuration"
  default = {
    min_size         = 2
    max_size         = 5
    desired_capacity = 2
  }
}

variable "ingressRule" {
  type        = list(number)
  default     = [80, 443]
  description = "description"
}
variable "egressRule" {
  type        = list(number)
  default     = [80, 443]
  description = "description"
}

variable "settings" {
  description = "configurations"
  type        = map(any)
  default = {
    database = {
      allocated_storage    = 10
      db_name              = "mydb"
      engine               = "mysql"
      engine_version       = "5.7"
      instance_class       = "db.t2.micro"
      username             = "foo"
      password             = "foobarbaz"
      parameter_group_name = "default.mysql5.7"
      skip_final_snapshot  = true
    }
  }
}


# for open the ssh port for testing, refer to custom_sg_rules.tfvars
variable "custom_db_sg_ingress_rules" {
  description = "Custom ingress rules for the DB security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}
