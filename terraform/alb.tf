#1. Application Load Balancer (ALB), 2.Target Group, 3.Listener, and Attachments

#1.Application Load Balancer (ALB)
resource "aws_lb" "app_lb" {
  name               = "app-lb"
  load_balancer_type = "application"
  subnets            = aws_subnet.public[*].id
  security_groups    = [aws_security_group.lb_sg.id]
  drop_invalid_header_fields = true
  enable_deletion_protection = true
  depends_on = [aws_internet_gateway.gw]
  tags = {
    Name = "app-lb"
  }
}

#2. Target Group
######## need configuring ##########
# Target Group
resource "aws_lb_target_group" "app_tg" {
  name     = "web-ec2-tg"
  vpc_id   = aws_vpc.main.id
  protocol = "HTTP"
  port     = 80
  target_type = "ip"
  deregistration_delay = 30

  health_check{
    enabled             = true
    path                = "/"
    port                = 80
    matcher             = 200
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    
  }

  tags = {
    Name = "app-tg"
  }
}



#3. Listener

# Listener for HTTPS
resource "aws_lb_listener" "app_lb_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port     = "443"
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = data.aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg-lb-ecs.arn

}   

}
#Redirect HTTP to HTTPS
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}