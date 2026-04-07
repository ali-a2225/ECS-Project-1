resource "aws_route53_zone" "main" {
  name         = var.domain_name
}

#DNS name to Load Balancer Domain Name mapping
resource "aws_route53_record" "dm" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.alb_url
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Subdomain -> ALB
resource "aws_route53_record" "tm_dm" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "tm.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_url
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}