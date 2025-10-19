output "alb_url" {
  value = aws_lb.app_lb.dns_name
}

output "alb_zone_id" {
  value = aws_lb.app_lb.zone_id
}

output "target_group_arn" {
  value = aws_lb_target_group.tg-lb-ecs.arn
}