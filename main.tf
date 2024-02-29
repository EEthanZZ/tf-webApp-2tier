provider "aws" {
  region = "us-east-2"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                 = "default"
}

module "networking" {
  source = "./modules/networking.tf"
  
  region               = var.region
  availability_zones   = var.availability_zones
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "auto_scaling_group" {
  source = "./modules/asg.tf"
  
  instance_type          = var.instance_type
  auto_scaling_group     = var.auto_scaling_group
}

module "load_balancing" {
  source = "./modules/lb.tf"
}

module "security_group" {
  source = "./modules/sg.tf"
  ingressRule = var.ingressRule
}