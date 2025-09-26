
####### ECR ##########
#Read from an ECR repository with Docker images
data "aws_ecr_repository" "web_ecr_repo" {
  name = "gatus" 
}

####### ECS ##########
#Create encryption key for encrypting session data and logs sent to CloudWatch
resource "aws_kms_key" "simple" {
  description = "KMS key for ECS Exec logging"
}

##Create an ECS Cluster
resource "aws_ecs_cluster" "web_ecs_cluster" {
  name = "gatus"
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
  #task_role_arn   = aws_iam_role.ECS_Task_Role.arn
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

          containerPort = 8080
          hostPort      = 8080
          protocol = "TCP"
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
    Name = "gatus-task"
  }
  depends_on = [aws_iam_role_policy.ECS_Task_Role_Policy]
}

# ECS Service
resource "aws_ecs_service" "gatus_service" {
  name            = "gatus-service"

  cluster         = aws_ecs_cluster.web_ecs_cluster.id
  task_definition = aws_ecs_task_definition.web_task.arn
  desired_count   = 1
  network_configuration {
    subnets         = aws_subnet.private[*].id
    security_groups = [aws_security_group.web_sg.id]
    assign_public_ip = false
  }
  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.asg_capacity_provider.name
  }

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100  
  #ECS will register and deregister tasks with this target group
  load_balancer {
    target_group_arn = aws_lb_target_group.tg-lb-ecs.arn
    container_name   = "first"
    container_port   = 8080
  }
  ordered_placement_strategy {
    type  = "binpack"
    field = "memory"
  }
  lifecycle {
    create_before_destroy = true
  }
  provisioner "local-exec" {
    when    = destroy
    command = "aws ecs update-service --cluster ${self.cluster} --service ${self.name} --desired-count 0"
  }
}

# Create a Capacity Provider for the Web Auto Scaling Group
resource "aws_ecs_capacity_provider" "asg_capacity_provider" {
  name = "asg-capacity-provider"
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.web_asg.arn
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
}

#Cloudwatch log qroup for ECS tasks
resource "aws_cloudwatch_log_group" "ecs" {
  name = "/ecs/demo"
  retention_in_days = 14
}