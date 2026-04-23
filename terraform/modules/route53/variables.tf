variable "alb_zone_id" {}
variable "alb_url" {}
variable "domain_name" {}
variable "cert_arn" {}
variable "domain_validation_options" {
    type = list(object({
        domain_name = string
        resource_record_name = string
        resource_record_type = string
        resource_record_value = string
    }))
}
variable "GODADDY_API_KEY" {
  description = "GoDaddy API Key"
  type        = string
  sensitive   = true
}
variable "GODADDY_API_SECRET" {
  description = "GoDaddy API Secret"
  type        = string
  sensitive   = true
}