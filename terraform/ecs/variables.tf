variable "web_asg_arn" {}
variable "ECS_Agent_Role_ARN" {}
variable "private_subnets" {
  type = list(string)
}
variable "target_group_arn" {}
variable "web_sg_id" {}