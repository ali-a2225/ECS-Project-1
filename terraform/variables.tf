variable "hostPort" {type = number}
variable "app_name" {type = string}
variable "web_ecs_cluster" {type = string}
variable "containerPort" {type = number}
variable "tf_state_bucket_name" {type = string}
variable "domain_name" {type = string}
variable "GODADDY_API_KEY" {
  description = "GoDaddy API Key"
  type        = string
  sensitive   = true
  default = ""
}
variable "GODADDY_API_SECRET" {
  description = "GoDaddy API Secret"
  type        = string
  sensitive   = true
  default = ""
}