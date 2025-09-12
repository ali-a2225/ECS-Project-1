#Application Load Balancer (ALB), Target Group, Listener, and Attachments






#Load Balancer
resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false ###<- look up
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = aws_subnet.public[*].id






  ####improve #############################################
  # URL: http://app-lb-1234567890.eu-west-1.elb.amazonaws.com
  url      ="http://${aws_lb.app_lb.dns_name}"
  
  listener {
    port     = "80"
    protocol = "HTTP"

    default_action {
      type             = "forward"
      target_group_arn = aws_lb_target_group.app_tg.arn
    }
  }

  depend_on = [aws_internet_gateway.gw]
    ####################################################


  tags = {
    Name = "app-lb"
  }
}








######## need configuring ##########
# Target Group
resource "aws_lb_target_group" "app_tg" {
  name     = "web-ec2-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}



  health_check{
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "app-tg"
  }
}


# Listener

######## need configuring ##########
resource "aws_lb_listener" "app_lb_listener" {
    load_balancer_arn = aws_lb.app_lb.arn

    port     = "80"
    protocol = "HTTP"
    default_action {
      type             = "forward"
      target_group_arn = aws_lb_target_group.app_tg.arn
    }

}   
