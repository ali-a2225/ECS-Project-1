variable "vpc_id"  {}
variable "web_sg_id" {}
variable "EC2_Instance_Profile_ARN" {}
variable "web_ecs_cluster_name" {}
variable "private_subnets" {
  type = list(string)
}