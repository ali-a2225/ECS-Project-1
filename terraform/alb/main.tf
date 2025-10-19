#1. Application Load Balancer (ALB), 2.Target Group (in Resources), 3.Listener, and Attachments

#1.Application Load Balancer (ALB)
resource "aws_lb" "app_lb" {
  name               = "app-lb"
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = var.load_balancer_security_group
  drop_invalid_header_fields = true
  #enable_deletion_protection = true
  depends_on = [var.internet_gateway_id]
  tags = {
    Name = "app-lb"
  }
}

#Create Target Group for Load Balancer
resource "aws_lb_target_group" "tg-lb-ecs" {
  name     = "tg-lb-ecs"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"
  health_check {
  enabled             = true  
  path                = "/"
  port                = "traffic-port"
  protocol = "HTTP"
  matcher             = 200
  interval            = 300
  timeout             = 120
  healthy_threshold   = 4
  unhealthy_threshold = 3
  }

  lifecycle {
    create_before_destroy = true
  }
}

#3. Listener

# Listener for HTTPS
resource "aws_lb_listener" "app_lb_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port     = "443"
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = var.cert_arn

  default_action {
    type             = "forward"
    target_group_arn = var.target_group_arn

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