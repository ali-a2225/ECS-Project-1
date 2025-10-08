output "load_balancer_sg_id" {
    value = aws_security_group.lb_sg.id
    description = "ALB Security Group ID"
}

output "web_sg_id" {
    value = aws_security_group.web_sg.id
    description = "EC2 Instances Security Group ID"
}