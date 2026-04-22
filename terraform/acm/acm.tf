# data "aws_acm_certificate" "cert" {
#   domain   = var.domain_name
#   statuses = ["ISSUED"]
# }

resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  # prove I own the domain by creating a DNS record in Route53
  validation_method = "DNS"

  # subject_alternative_names = [
  #   "*.${var.domain_name}"
  # ]

  lifecycle {
    create_before_destroy = true
  }
}

# Forces tf to wait until ACM certificate is validated
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  # collects all validation records created
  validation_record_fqdns =  var.cert_validation
  depends_on = [var.cert_validation]
}



# output "cert_arn" {
#   value = data.aws_acm_certificate.cert.arn
# }