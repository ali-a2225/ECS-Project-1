# Overview

This project is based on Amazon's Threat Composer Tool, an open source tool designed to facilitate threat modelling and improve security assessments.  




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
    - a Record (alias) pointing to the ALB DNS name

**IAM**
- Task Role provides permissions required by ECS tasks
- EC2 Role allows ECS instances to join the ECS cluster and pull images from Amazon ECR

**CloudWatch**
    - collects logs from the ECS cluster for observability and debugging.



