output "route53_record_name" {
    value = [aws_route53_record.dm.name]
}
output "cert_validation" {
  value       = [for record in aws_route53_record.cert_validation : record.fqdn]
  description = "List of domain validation record names for ACM certificate"
}
output "name_servers" {
  value       = data.aws_route53_zone.main.name_servers
  description = "Name servers for the hosted zone"
}