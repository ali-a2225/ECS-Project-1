output "name_servers" {
  value       = aws_route53_zone.main.name_servers
  description = "Name servers for the hosted zone"
}