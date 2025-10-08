data "aws_acm_certificate" "cert" {
  domain   = "aliabukar.com"
  statuses = ["ISSUED"]
}

output "cert_arn" {
  value = data.aws_acm_certificate.cert.arn
}