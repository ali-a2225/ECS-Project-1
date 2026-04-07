output "web_asg_arn" {
    value = aws_autoscaling_group.web_asg.arn
    description = "Auto Scaling Group arn"
}