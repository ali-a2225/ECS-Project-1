output "ECS_Agent_Role_ARN"{
    value = aws_iam_role.ECS_Agent_Role.arn
    description = "ECS Agent Role ARN"
}
/*
output "ECS_Task_Role_ARN"{
    value = aws_iam_role.ECS_Task_Role.arn
    description = "ECS Task Role ARN"
}

*/
output "EC2_Instance_Profile_ARN"{
    value = aws_iam_instance_profile.EC2_Instance_Profile.arn
    description = "ECS Instance Profile ARN"
}