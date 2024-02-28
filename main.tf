provider aws {
  region = var.region
}

# vpc
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}

#public subnet
resource "aws_subnet" "public_subnet_1" {
    vpc_id            = aws_vpc.main.id
    cidr_block        = var.public_subnet_cidrs[0]
    availability_zone = var.availability_zones[0]
}

resource "aws_subnet" "public_subnet_2" {
    vpc_id            = aws_vpc.main.id
    cidr_block        = var.public_subnet_cidrs[1]
    availability_zone = var.availability_zones[1]
}

#private subnet
resource "aws_subnet" "private_subnet_1" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_cidrs[0]
    availability_zone = var.availability_zones[0]
}

resource "aws_subnet" "private_subnet_2" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_cidrs[1]
    availability_zone = var.availability_zones[1]
}

#gateway & route table
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }
}

# Associate the public subnets with the public route table
resource "aws_route_table_association" "public_route_table_association_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_route_table_association_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

# Associate the private subnets with the private route table
resource "aws_route_table_association" "private_route_table_association_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_route_table_association_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}

# Get the latest AWS Linux 2023 image
data "aws_ami" "amazon2023" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
    filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Launch the ASG using AmazonLinux 2023
# launch template configuration
resource "aws_launch_configuration" "asg_config" {
  name_prefix          = "myASG-"
  image_id      = data.aws_ami.amazon2023.id
  instance_type = var.instance_type
  associate_public_ip_address = true
    lifecycle {
    create_before_destroy = true
  }
}
# launch in private subnets
resource "aws_autoscaling_group" "asg" {
    name = "asg"
    launch_configuration = aws_launch_configuration.asg_config.name
    min_size = var.auto_scaling_group["min_size"]
    max_size = var.auto_scaling_group["max_size"]
    vpc_zone_identifier = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}