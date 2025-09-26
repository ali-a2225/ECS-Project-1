data "aws_acm_certificate" "cert" {
  domain   = "aliabukar.com"
  statuses = ["ISSUED"]
}