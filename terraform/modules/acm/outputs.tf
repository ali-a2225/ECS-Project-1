# output "cert_arn" {
#   value = aws_acm_certificate.cert.arn
# }
# validated cert
output "cert_arn" {
  value = aws_acm_certificate_validation.cert_validation.certificate_arn
}

output "domain_validation_options" {
  value       = aws_acm_certificate.cert.domain_validation_options
  description = "Domain validation records for ACM certificate"
}

output "cert_validation" {
  value       = aws_acm_certificate_validation.cert_validation.validation_record_fqdns
  description = "FQDNs of the DNS validation records created for ACM certificate"
}