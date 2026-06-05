variable "az_count" {
  description = "Number of AZs to spread subnets across"
  type        = number
  default     = 1
}
variable "public_subnets" {
  description = "Number of public subnets to create"
  type        = number
  default     = 1
}