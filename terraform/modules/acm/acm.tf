# data "aws_acm_certificate" "cert" {
#   domain   = var.domain_name
#   statuses = ["ISSUED"]
# }

data "aws_route53_zone" "main" {
  name = var.domain_name
}


resource "aws_acm_certificate" "cert" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"] # <-- for subdomains
  # prove I own the domain by creating a DNS record in Route53
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

# Validation records
## detects what ACM needs and automatically creates the records needed by ACM certificate
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  #create the record in Route53 to validate the ACM certificate
  name            = each.value.name
  records         = [each.value.record]
  type            = each.value.type
  ttl             = 60
  zone_id         = data.aws_route53_zone.main.zone_id
  allow_overwrite = true #  prevents conflicts when the main domain and wildcard domain share a validation record.

  lifecycle {
    create_before_destroy = true
  }
}


# Forces tf to wait until ACM certificate is validated
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn = aws_acm_certificate.cert.arn
  # collects all validation records created
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  # depends_on = [var.cert_validation]
}
# output "cert_arn" {
#   value = data.aws_acm_certificate.cert.arn
# }