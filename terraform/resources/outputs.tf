output "web_asg_arn" {
    value = aws_autoscaling_group.web_asg.arn
    description = "Auto Scaling Group arn"
}

output "target_group_arn" {
  value = aws_lb_target_group.tg-lb-ecs.arn
}