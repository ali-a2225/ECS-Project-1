#Create Target Group for Load Balancer
resource "aws_lb_target_group" "tg-lb-ecs" {
  name     = "tg-lb-ecs"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
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

data "aws_ssm_parameter" "ecs_node_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

#Launch Template for EC2 instances 
resource "aws_launch_template" "EC2_Launch_Template" {

  name = "EC2_Resources_ECS_Cluster"
  image_id  = data.aws_ssm_parameter.ecs_node_ami.value
  instance_type = "t2.micro"
  iam_instance_profile {
    arn = aws_iam_instance_profile.EC2_Instance_Profile.arn
  }
  instance_initiated_shutdown_behavior = "terminate"
  monitoring {
    enabled = true
  }
  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
    device_index                = 0
    security_groups             = [aws_security_group.web_sg.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ECS Instance"
    }
  }
  user_data = base64encode(<<-EOF
      #!/bin/bash
      echo ECS_CLUSTER=${aws_ecs_cluster.web_ecs_cluster.name} >> /etc/ecs/ecs.config;
    EOF
  )

} 

#Auto Scaling Group
resource "aws_autoscaling_group" "web_asg" {
  desired_capacity     = 2
  max_size             = 3
  min_size             = 1
  vpc_zone_identifier  = aws_subnet.private[*].id
  launch_template {
    id      = aws_launch_template.EC2_Launch_Template.id
    version = "$Latest"
  }
  health_check_type   = "EC2"
  health_check_grace_period = 300
  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true

  }
  depends_on = [aws_iam_instance_profile.EC2_Instance_Profile]
}