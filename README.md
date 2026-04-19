# Scalable ECS Architecture with Gatus

Gatus is a health dashboard that monitors services over HTTP, ICMP, TCP and DNS queries, and evaluates the results based on collected metrics.

This repo contains Terraform code to deploy a scalable, highly available architecture on AWS ECS (EC2 launch type). The setup includes:

- Dockerised Gatus app
- CI/CD pipeline – GitHub Actions workflow to build, test, and push the Docker image to Amazon ECR  
- Infrastructure – managed by Terraform, provisioning ECS clusters, EC2 instances, security groups, and an Application Load Balancer (ALB)
- Security – SSL certificates, automatic HTTP → HTTPS redirects, security groups and least-privilege configurations for usability without compromising security
- DNS – Route53 A record mapping the domain to the ALB DNS name.


![images](https://github.com/ali-a2225/ECS-Project-1/blob/d125e490ec0f8c8e57a5a697869e7ea713423572/images/infra-diagram%20Gatus.jpg)

## VPC 

**Networking**
- region: `eu-west-2`
- 3 Public subnets, one in each Availability Zone (AZ).
- 3 Private subnets, one in each AZ.
- 1 Internet Gateway (IGW) providing internet access for resources in a public subnet
- 3 NAT Gateways (one per AZ) providing outbound internet access for private subnets.
- 1 Public route → IGW
- 3 Private routes → 3 NAT Gateway in the corresponding AZ for high availability.

**Application Load Balancer (ALB)**
- deployed across all 3 public subnets.
- distributes traffic to containers registered in a Target Group.
- HTTPS (port 443) listener with SSL certificate.
- HTTP listener → HTTPS redirection for encryption.

**ECS Service**
- registers tasks' IP addresses with the ALB Target Group
- uses AWS VPC networking mode, creating an ENI for each container.

**Auto Scaling Group (ASG)**
- scales EC2 instances in or out based on demand

**Capacity Provider**
- abstracts underlying EC2 resources for ECS services
- works with ASG

**Security Groups**
- allow inbound HTTPS (`443`) from `0.0.0.0/0` to the ALB
- allow traffic from ALB to ECS tasks only

**Route53:**
- a record (alias) pointing to the ALB DNS name

**IAM**
- Task Role provides permissions required by ECS tasks
- EC2 Role allows ECS instances to join the ECS cluster and pull images from Amazon ECR

**CloudWatch**
- collects logs from the ECS cluster for observability and debugging.

## **Tree**
```
.
├── README.md
├── app
│   ├── Dockerfile
│   └── config
│       └── config.yaml
├── acm
│   ├── acm.tf
│   └── outputs.tf
├── alb
│   ├── main.tf
│   ├── output.tf
│   └── variables.tf
├── ecs
│   ├── ecs.tf
│   ├── outputs.tf
│   └── variables.tf
├── iam
│   ├── iam.tf
│   └── outputs.tf
├── resources
│   ├── outputs.tf
│   ├── resources.tf
│   └── variables.tf
├── route53
│   ├── route53.tf
│   └── variables.tf
├── secgroups
│   ├── outputs.tf
│   ├── secgroups.tf
│   └── variables.tf
└── vpc
│   ├── outputs.tf
│   └── vpc.tf
├── main.tf
├── provider.tf
└── variables.tf

```

## Getting Started
1. Clone the repo  
2. Configure AWS credentials  
3. Run `terraform init && terraform apply`  
4. Deploy the application via GitHub Actions  


## Further Improvements

 - [X] state versioning
- [ ] create scripts to perform checks for ECS and other resources
- [ ] create own provider and module to work with GoDaddy
- [ ] create action to list all resources currently in use on AWS
- [ ] create script to watch ECS service live as tasks are being created and when being destroyed, it would be useful for troubleshooting.
- [ ] create VPC endpoints to lower the costs of NAT gateways
- [ ] consider decreasing the number of AZs
- [ ] store config.yaml in S3 bucket and pass it to the tasks at runtime rather than in the container image
- [ ] enable tagging of resources
- [ ] move all the terraform folder in folder terraform/modules and move bootstrap into terraform/bootstrap
- [ ] experiment with FinOps. See what other decisions I can make to cut costs
