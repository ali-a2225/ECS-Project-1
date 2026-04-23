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
  # trigger if NS changes
    triggers = {
    ns_hash = sha1(join(",", data.aws_route53_zone.main.name_servers))
  }

  provisioner "local-exec" {
  # execute following string as a bash command
  interpreter = ["/bin/bash", "-c"]
  # pass to script as env vars to keep out of terraform logs
  environment = {
  GODADDY_API_KEY    = var.GODADDY_API_KEY
  GODADDY_API_SECRET = var.GODADDY_API_SECRET
  DOMAIN             = var.domain_name
  NS1                = data.aws_route53_zone.main.name_servers[0]
  NS2                = data.aws_route53_zone.main.name_servers[1]
  }

  command = <<EOT
  set -euo pipefail

  curl -f -X PATCH \
  "https://api.godaddy.com/api/v1/domains/$${DOMAIN}" \
  -H "Authorization: sso-key $${GODADDY_API_KEY}:$${GODADDY_API_SECRET}" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg ns1 "$${NS1}" --arg ns2 "$${NS2}" '{nameServers: [$ns1, $ns2]}')"
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