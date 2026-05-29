plugin "aws" {
  enabled = true
  version = "0.47.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}


# EC2

rule "aws_instance_invalid_type" {
  enabled  = true
  severity = "error"
}

# validate format of AMI not its existence
rule "aws_instance_invalid_ami" {
  enabled  = true
  severity = "error"
}



# IAM

rule "aws_iam_role_deprecated_policy_attributes" {
  enabled  = true
  severity = "warning"
}


# SG

rule "aws_security_group_inline_rules" {
  enabled  = true 
  severity = "warning"
} 

rule "aws_security_group_rule_deprecated" {
  enabled = true
  severity = "warning"
}

# security groups
rule "aws_security_group_invalid_protocol" {
  enabled  = true
  severity = "error"
}

# Route53
# pending

# ALB

rule "aws_alb_invalid_ip_address_type" {
  enabled  = true
  severity = "error"
}

rule "aws_alb_invalid_load_balancer_type" {
  enabled  = true
  severity = "error"
}

rule "aws_alb_listener_invalid_protocol" {
  enabled  = true
  severity = "error"
}

rule "aws_alb_target_group_invalid_protocol" {
  enabled  = true
  severity = "error"
}

rule "aws_alb_target_group_invalid_target_type" {
  enabled  = true
  severity = "error"
}
# ACM 

# check for "create before destroy", this creates ACM cert before destroying to prevent downtime
rule "aws_acm_certificate_lifecycle" {
  enabled = true
  severity = "error"
}



# checks invalid certificate arn in aws_acm_cert_validation resource
rule "aws_acm_certificate_validation_invalid_certificate_arn" {
  enabled  = true
  severity = "error"
}

# Terraform 
rule "terraform_required_version" {
  enabled  = true
  severity = "warning"
}

rule "terraform_required_providers" {
  enabled  = true
}
