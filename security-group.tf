resource "aws_security_group" "alb-sg" {
  description = "Allow inbound traffic from anywhere on port 80 and 443"
  name        = "alb_sg"
  vpc_id      = aws_vpc.main.id
  
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
}

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
}
