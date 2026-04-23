variable "domain_name" {}
variable "route53_record_name" {
  type = list(string)
}
variable "cert_validation" {
  type = list(string)
}