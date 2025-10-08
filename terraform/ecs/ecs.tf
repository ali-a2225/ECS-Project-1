####### ECR ##########
#Read from an ECR repository with Docker images
data "aws_ecr_repository" "web_ecr_repo" {
  name = "gatus" 
}

####### ECS ##########

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
  execution_role_arn = var.ECS_Agent_Role_ARN
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
      },
      "readonlyRootFilesystem": true
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
  #depends_on = [aws_iam_role_policy.ECS_Task_Role_Policy]
}

# ECS Service
resource "aws_ecs_service" "gatus_service" {
  name            = "gatus-service"

  cluster         = aws_ecs_cluster.web_ecs_cluster.id
  task_definition = aws_ecs_task_definition.web_task.arn
  desired_count   = 1
  network_configuration {
    subnets         = var.private_subnets
    security_groups = [var.web_sg_id]
    assign_public_ip = false
  }
  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.asg_capacity_provider.name
    weight = 1
  }

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100  
  #ECS will register and deregister tasks with this target group
  load_balancer {
    target_group_arn = var.target_group_arn
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
    auto_scaling_group_arn         = var.web_asg_arn
    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 75
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 2
    }
  }
  depends_on = [var.web_asg_arn]
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
  retention_in_days = 365

}