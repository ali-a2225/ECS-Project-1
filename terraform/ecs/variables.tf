variable "vpc_id" {}
variable "web_asg_arn" {}
variable "ECS_Agent_Role_ARN" {}
variable "private_subnets" {
  type = list(string)
}
variable "target_group_arn" {}
variable "web_sg_id" {}
variable "containerPort" {
  default = 8080
  type = number
}
variable "hostPort" {
  default = 8080
  type = number
}
variable "app_name" {type = string}
variable "web_ecs_cluster" { type = string}

