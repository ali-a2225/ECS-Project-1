output "cert_arn" {
  value = aws_acm_certificate.cert.arn
}


output "domain_validation_options" {
  value = aws_acm_certificate.cert.domain_validation_options
  description = "Domain validation records for ACM certificate"
}