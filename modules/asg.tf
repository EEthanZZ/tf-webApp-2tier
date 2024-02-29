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
 
resource "aws_autoscaling_group" "asg" {
  name                 = "asg"
  launch_configuration = aws_launch_configuration.asg_config.name
  min_size             = var.auto_scaling_group["min_size"]
  max_size             = var.auto_scaling_group["max_size"]
  desired_capacity     = var.auto_scaling_group["desired_capacity"]
  vpc_zone_identifier  = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  
  target_group_arns = [aws_lb_target_group.tg.arn]
  
  tag {
    key                 = "Name"
    value               = "ASG Instances"
    propagate_at_launch = true
  }
}

