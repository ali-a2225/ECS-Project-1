# data "aws_acm_certificate" "cert" {
#   domain   = var.domain_name
#   statuses = ["ISSUED"]
# }

resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.dm : record.fqdn]
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn = aws_acm_certificate.cert.arn

  validation_record_fqdns = [
    for record in aws_route53_record.cert_validation : record.fqdn
  ]
}

# output "cert_arn" {
#   value = data.aws_acm_certificate.cert.arn
# }