#EC2 instances in Public & Private Subnet and Security Group

/*
# EC2 Instances in Public Subnet
resource "aws_instance" "web" {
    count         = 3
  ami           = "test" 
  instance_type = "test"
  subnet_id     = element(aws_subnet.public[*].id, count.index)
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  availability_zone = "eu-west-1${element(["a","b","c"], count.index)}"

  tags = {
    Name = "web-server-${count.index + 1}"
  }

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World from $(hostname -f)" > /usr/share/nginx/html/index.html
              yum install -y nginx
              systemctl start nginx
              systemctl enable nginx
              EOF
}

*/


/*
#Add EC2 instances to Target Group
aws_lb_target_group_attachment "web_tg_ec2" {
    count            = length(aws_instance.web)
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}
*/

#Create Target Group for Load Balancer
resource "aws_lb_target_group" "tg-lb-ecs" {
  name     = "tg-lb-ecs"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = aws_vpc.main.id
  target_type = "ip"

  health_check {
  enabled             = true   
  path                = "/health"
  port                = 443
  matcher             = 200
  interval            = 30
  timeout             = 10
  healthy_threshold   = 4
  unhealthy_threshold = 3

}
}



#Register Target Group with ECS Service




#Register Target Group 



#ALB URL in output
output "alb_url" {
  value = aws_lb.app_lb.dns_name
}



#Launch Template for EC2 instances 
resource "aws_launch_template" "EC2_Launch_Template" {

  name = "EC2_Resources_ECS_Cluster"

  #specify the IAM role created in iam/main.tf
  iam_instance_profile {
    name = "EC2_Instance_Profile"
  }

  #instance type
  instance_type = "t2.micro"
  #image ID
  image_id = "ami-0971f6afca696ace6" 

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
              echo "ECS_CLUSTER=${aws_ecs_cluster.web_ecs_cluster.name}" >> /etc/ecs/ecs.config
              EOF
  )

} 




#Auto Scaling Group
resource "aws_autoscaling_group" "web_asg" {
  desired_capacity     = 3
  max_size             = 4
  min_size             = 1
  vpc_zone_identifier  = aws_subnet.private[*].id
  launch_template {
    id      = aws_launch_template.EC2_Launch_Template.id
    version = "$Latest"
  }
  #?
  health_check_type   = "EC2"
  #?
  health_check_grace_period = 300

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true

  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_iam_instance_profile.EC2_Instance_Profile]
}


####### ECR ##########
#Create an ECR repository to store Docker images
data "aws_ecr_repository" "web_ecr_repo" {
  name = "my-ecr-repo" 
}





####### ECS ##########

resource "aws_kms_key" "simple" {
  description = "KMS key for ECS Exec logging"
}


##Create an ECS Cluster
resource "aws_ecs_cluster" "web_ecs_cluster" {
  name = "memos"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      kms_key_id = aws_kms_key.simple.arn
      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name = aws_cloudwatch_log_group.ecs.name
      }
  
    }
  }
}



#ECS task definition
resource "aws_ecs_task_definition" "web_task" {

  family = "service"
  task_role_arn   = aws_iam_role.ECS_Task_Role.arn
  execution_role_arn = aws_iam_role.ECS_Agent_Role.arn
  network_mode     = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu              = 256
  memory           = 512

  container_definitions = jsonencode([
    {
      name      = "first"
      image     = "${data.aws_ecr_repository.web_ecr_repo.repository_url}:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 443
          hostPort      = 443
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = "eu-west-2"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ]
  )




  volume {
    name      = "service-storage"
    host_path = "/ecs/service-storage"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [eu-west-2a, eu-west-2b, eu-west-2c]"
  }

  tags = {
    Name = "memos-task"
  }
  depends_on = [aws_iam_role_policy.ECS_Task_Role_Policy]

}



# ECS Service
resource "aws_ecs_service" "memo_service" {
  name            = "memos-service"

  cluster         = aws_ecs_cluster.web_ecs_cluster.id
  task_definition = aws_ecs_task_definition.web_task.arn
  
  desired_count   = 2 ##of what?

  ####################Network configuration for the service
  network_configuration {
    subnets         = aws_subnet.private[*].id
    security_groups = [aws_security_group.web_sg.id]
    assign_public_ip = false
  }


  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.asg_capacity_provider.name
    weight            = 1
  }

  deployment_minimum_healthy_percent = 50 #???
  deployment_maximum_percent         = 200  
  health_check_grace_period_seconds  = 300

  #######################  
  load_balancer {
    target_group_arn = aws_lb_target_group.tg-lb-ecs.arn
    container_name   = "first"
    container_port   = 443
  }

  ordered_placement_strategy {
    type  = "binpack"
    field = "memory"
  }

  depends_on = [aws_lb_listener.app_lb_listener]
}


# Create a Capacity Provider for the Web Auto Scaling Group
resource "aws_ecs_capacity_provider" "asg_capacity_provider" {
  name = "asg-capacity-provider"



  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.web_asg.arn
    #?
    managed_termination_protection = "DISABLED"
    
    #?
    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 75
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 2
    }
  }

  depends_on = [aws_autoscaling_group.web_asg]
}


# Attach the Capacity Provider to the ECS Cluster
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.web_ecs_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.asg_capacity_provider.name]
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.asg_capacity_provider.name
    weight            = 100
    base              = 1
  }
  
  depends_on = [aws_ecs_cluster.web_ecs_cluster]
}





#Cloudwatch log qroup for ECS tasks
resource "aws_cloudwatch_log_group" "ecs" {
  name = "/ecs/demo"
  retention_in_days = 14
}



