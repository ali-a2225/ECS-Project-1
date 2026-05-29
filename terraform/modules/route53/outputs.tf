output "route53_record_name" {
  value = [aws_route53_record.dm.name]
}
output "name_servers" {
  value       = data.aws_route53_zone.main.name_servers
  description = "Name servers for the hosted zone"
}