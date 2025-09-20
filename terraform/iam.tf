# Create an IAM role for EC2 instances to register with ECS
resource "aws_iam_role" "EC2_Role" {
  name = "EC2_Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}



## Define the trust relationship for the role

resource "aws_iam_role_policy" "EC2_Role_Policy" {
  name = "EC2_Role_Policy"
  role = aws_iam_role.EC2_Role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
                "ec2:DescribeTags",
                "ecs:CreateCluster",
                "ecs:DeregisterContainerInstance",
                "ecs:DiscoverPollEndpoint",
                "ecs:Poll",
                "ecs:RegisterContainerInstance",
                "ecs:StartTelemetrySession",
                "ecs:UpdateContainerInstancesState",
                "ecs:Submit*",
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
        ],
        Resource = "*"
      },
    {
        Effect: "Allow",
        Action: "ecs:TagResource",
        Resource: "*",
        Condition: {
            "StringEquals": {
                "ecs:CreateAction": [
                    "CreateCluster",
                    "RegisterContainerInstance"
                ]
            }
        }

    },
    {
        Effect: "Allow",
        Action: [
                "ecs:ListTagsForResource"
        ],
            Resource: [
                "arn:aws:ecs:*:*:task/*/*",
                "arn:aws:ecs:*:*:container-instance/*/*"
            ]

    }
    ]
  })
}



#Create an instance profile to attach the role to EC2 instances in launch template
resource "aws_iam_instance_profile" "EC2_Instance_Profile" {
  name = "EC2_Instance_Profile"
  role = aws_iam_role.EC2_Role.name
}


##################################
##################################
#############  ECS  ##############
##################################
##################################






# Create an IAM role for ECS Agents to use 
resource "aws_iam_role" "ECS_Agent_Role" {
  name = "ECS_Task_Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}


## Define the trust relationship for the role
resource aws_iam_role_policy_attachment "ECS_Agent_Role_Policy" {
  role       = aws_iam_role.ECS_Agent_Role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#####################################

# Create an IAM role for ECS tasks to use
resource "aws_iam_role" "ECS_Task_Role" {
  name = "ECS_Task_Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}


## Define the trust relationship for task role
resource "aws_iam_role_policy" "ECS_Task_Role_Policy" {
  name = "ECS_Task_Role_Policy"
  role = aws_iam_role.ECS_Task_Role.name


  #define the permissions for the TASK role
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
                "s3:*",
                "dynamodb:*"
        ],
        Resource = "*"
      },
    ]
  })


}
