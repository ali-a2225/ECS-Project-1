data "aws_route53_zone" "main" {
  name         = var.domain_name
}

# Validation records
## detects what ACM needs and automatically creates the records needed by ACM certificate
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in var.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  
  #create the record in Route53 to validate the ACM certificate
  name    = each.value.name
  records = [each.value.record]
  type    = each.value.type
  ttl     = 60
  zone_id = data.aws_route53_zone.main.zone_id

  lifecycle {
    create_before_destroy = true
  }
}

# Create DNS records in GoDaddy

resource "null_resource" "godaddy_dns" {
  provisioner "local-exec" {
    command = <<EOT
    curl -X PATCH \
  "https://api.godaddy.com/api/v1/domains/${var.domain_name}" \
  -H "Authorization: sso-key ${var.GODADDY_API_KEY }:${var.GODADDY_API_SECRET}" \
  -H "Content-Type: application/json" \
  -d '{
    "nameServers": [
      "${data.aws_route53_zone.main.name_servers[0]}",
      "${data.aws_route53_zone.main.name_servers[1]}"
    ]
  }'
    EOT
  }
}



#DNS name to Load Balancer Domain Name mapping
resource "aws_route53_record" "dm" {
  zone_id = data.aws_route53_zone.main.zone_id
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
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "tm.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_url
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}