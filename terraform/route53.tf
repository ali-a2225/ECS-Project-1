data "aws_route53_zone" "main" {
  name         = "aliabukar.com"

}

#DNS name to Load Balancer Domain Name mapping
resource "aws_route53_record" "dm" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "aliabukar.com"
  type    = "A"

  alias {
    name                   = aws_lb.app_lb.dns_name
    zone_id                = aws_lb.app_lb.zone_id
    evaluate_target_health = true
  }
}

# Subdomain -> ALB
resource "aws_route53_record" "tm_dm" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "tm.aliabukar.com"
  type    = "A"

  alias {
    name                   = aws_lb.app_lb.dns_name
    zone_id                = aws_lb.app_lb.zone_id
    evaluate_target_health = true
  }
}



