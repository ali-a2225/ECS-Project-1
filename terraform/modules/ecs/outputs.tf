output "web_ecs_cluster_name" {
    value = aws_ecs_cluster.web_ecs_cluster.name
    description = "ECS Cluster Name"
}