
variable "public_subnets" {}
variable "load_balancer_security_group" {}
variable "vpc_id" {}
variable "internet_gateway_id" {}
variable "cert_arn" {}
variable "containerPort" {
  description = "The port on which the container listens for traffic"
  type        = number
  default     = 8080
}
variable "cert_validation" {
  description = "Certificate validation status from ACM module"
}