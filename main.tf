provider "aws" {
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
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[0]
  availability_zone = var.availability_zones[0]
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[1]
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
  owners      = ["amazon"]
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
  name_prefix                 = "myASG-"
  image_id                    = data.aws_ami.amazon2023.id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  security_groups             = [aws_security_group.asg-sg.id]
  lifecycle {
    create_before_destroy = true
  }
  user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y
                sudo yum install -y httpd
                sudo systemctl start httpd
                sudo systemctl enable httpd
                INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
                AVAILABILITY_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
                REGION=$${AVAILABILITY_ZONE::-1}
                echo "<h1>LUIT Week21 - Johnny Mac - June 2023</h1>" | sudo tee /var/www/html/index.html
                echo "<p>Instance ID: $INSTANCE_ID</p>" | sudo tee -a /var/www/html/index.html
                echo "<p>Region: $REGION</p>" | sudo tee -a /var/www/html/index.html
                echo "<p>Availability Zone: $AVAILABILITY_ZONE</p>" | sudo tee -a /var/www/html/index.html
                sudo systemctl restart httpd
                EOF
}
# launch in private subnets
resource "aws_autoscaling_group" "asg" {
  name                 = "asg"
  launch_configuration = aws_launch_configuration.asg_config.name
  min_size             = var.auto_scaling_group["min_size"]
  max_size             = var.auto_scaling_group["max_size"]
  desired_capacity     = var.auto_scaling_group["desired_capacity"]
  vpc_zone_identifier  = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  # Associate ASG with ALB Target Group
  target_group_arns = [aws_lb_target_group.tg.arn]

  tag {
    key                 = "Name"
    value               = "ASG Instances"
    propagate_at_launch = true
  }
}

# Launch the ALB in public subnet
resource "aws_lb" "alb_public_sub" {
  name               = "alb-public"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}


# Target Group
resource "aws_lb_target_group" "tg" {
  name     = "alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    path                = "/"
    port                = "traffic-port"
  }
}
#ALB listener on port 80
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.alb_public_sub.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}


# Create a Security Group for the ALB

resource "aws_security_group" "alb-sg" {
  description = "Allow inbound traffic from anywhere on port 80 and 443"
  name        = "alb_sg"
  vpc_id      = aws_vpc.main.id  # Add this line to associate the security group with the VPC
  dynamic "ingress" {
    iterator = port
    for_each = var.ingressRule
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "alb_sg"
  }
}

# Create a Security Group for instances in the ASG
resource "aws_security_group" "asg-sg" {
  name        = "asg_sg"
  description = "Allow inbound traffic on port 80 from the ALB only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "asg-sg"
  }
}

output "lb_dns_name" {
  description = "The DNS name of our ALB"
  value       = aws_lb.alb_public_sub.dns_name
}