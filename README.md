# Scalable ECS Architecture with Gatus

Gatus is a health dashboard that monitors services over HTTP, ICMP, TCP and DNS queries, and evaluates the results based on collected metrics.

This repo contains Terraform code to deploy a scalable, highly available architecture on AWS ECS (EC2 launch type). The setup includes:

- Dockerised Gatus app
- CI/CD pipeline – GitHub Actions workflow to build, test, and push the Docker image to Amazon ECR  
- Infrastructure – managed by Terraform, provisioning ECS clusters, EC2 instances, security groups, and an Application Load Balancer (ALB)
- Security – SSL certificates, automatic HTTP → HTTPS redirects, security groups and least-privilege configurations for usability without compromising security
- DNS – Route53 A record mapping the domain to the ALB DNS name.


![images](https://github.com/ali-a2225/ECS-Project-1/blob/d125e490ec0f8c8e57a5a697869e7ea713423572/images/infra-diagram%20Gatus.jpg)

## Highlights
1. Zero-downtime ACM certificates — `create_before_destroy` on the certificate and its DNS validation records means a new cert is issued before the old one is removed.
2. Scale-to-zero on teardown — the ECS service uses a destroy-time local-exec provisioner that sets the desired task count to 0 and forces a new deployment before the service is destroyed, so capacity-provider managed termination protection doesn't block the destroy.
3. Automated nameserver delegation — a null_resource patches the domain's nameservers at the registrar (GoDaddy) to point at the Route53 hosted zone via the GoDaddy API, toggleable with skip_dns.


## Architecture

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
- allow inbound HTTPS (port `443`) from `0.0.0.0/0` to the ALB
- allow inbound HTTP (port `80`) from `0.0.0.0/0` to the ALB
- allow ONLY traffic from ALB to ECS tasks using SG chaining

**Route53:**
- A record (alias) pointing to the ALB DNS name
- A record (alias) for the tm. subdomain pointing to the same ALB

**IAM**
- ECS task execution role lets the agent pull images from ECR and write logs to CloudWatch
- EC2 Role allows ECS instances to join the ECS cluster and pull images from Amazon ECR

**CloudWatch**
- collects logs from the ECS cluster for observability and debugging.

## Prerequisites
The list below is for running Terraform locally. If you deploy through the GitHub Actions workflows instead, the runners install Terraform, tflint, Docker, and the AWS CLI for you.

- Terraform >= 1.5.0 (the pipeline pins 1.15.5)
- An AWS account. Locally, credentials via aws configure; in CI, access is via an OIDC role (no static keys)
- AWS CLI required by the ECS scale-to-zero destroy provisioner, the destroy will fail without it
- jq, curl, and bash used by the GoDaddy nameserver automation
- Docker to build the Gatus image
- registered domain whose nameservers you can change

## **Tree**
```
.
├── README.md
├── .github/
│   └── workflows/
│       ├── build.yaml          # build & push Docker image to ECR
│       ├── tfdeploy.yaml       # terraform apply
│       └── tfdestroy.yaml      # terraform destroy
├── app/                        # Gatus app (Dockerfile + config.yaml)
└── terraform/
    ├── main.tf                
    ├── provider.tf       
    ├── variables.tf
    ├── terraform.tfvars
    ├── .tflint.hcl
    ├── bootstrap/              # state bucket, ECR repo, hosted zone
    │   ├── main.tf
    │   ├── backend.tf          # local backend
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── terraform.tfvars
    └── modules/
        ├── acm/                # ACM certificate + DNS validation
        ├── alb/                # load balancer, target group, listeners
        ├── compute/            # launch template + Auto Scaling Group
        ├── ecs/                # cluster, task definition, service, capacity provider
        ├── iam/                # EC2 + ECS roles
        ├── route53/            # DNS records + GoDaddy nameserver automation
        ├── secgroups/          # ALB and ECS security groups
        └── vpc/                # VPC, subnets, NAT/IGW, routes


```

## Getting Started
1. Clone the repo  
2. Configure AWS credentials
3. Run `cd terraform/bootstrap && terraform init && terraform apply`
4. Delegate nameservers for your domain registrar to Route53
 a) manually
 b) obtain GoDaddy API keys and save them as secrets  and supplying GODADDY_API_KEY / GODADDY_API_SECRET. and set skip_dns to false to ensure the nameservers in GoDaddy are programmatically overwritten with those in Route53 
5. Manually setup OIDC trust relationship between AWS and GitHub
6. Build the Gatus image from app/ and push it to the ECR repo from step 1 locally or via the build workflow
7. Run `cd terraform && terraform init && terraform apply` # will use backend from bootstrap 
 
Once applied, the app is reachable at https://<your-domain>.


## CI/CD 

All three workflows authenticate to AWS via OIDC (no static access keys).

- build.yaml — on changes under app/** (or manual dispatch): builds the image, runs it and curls /health as a test, then pushes to ECR tagged with the commit SHA and latest.
- tfdeploy.yaml — on changes under terraform/**: a checks job runs fmt -check, validate, tflint, and plan; an apply job runs only if checks passes and the branch is main.
- tfdestroy.yaml — manual dispatch only; requires typing DESTROY TF to confirm, then runs terraform destroy.

Required repository secrets: 
- AWS_OIDC_ROLE (the role assumed via OIDC)
- GODADDY_API_KEY / GODADDY_API_SECRET only if skip_dns = false



## Teardown
- Run `cd terraform && terraform destroy` OR Run tfdestroy workflow

The tfdestroy workflow runs Terraform directly on the runner (not through the dflook container) on purpose: the scale-to-zero provisioner shells out to the AWS CLI, which the runner has but the action container does not.

Note S3 bucket and ECR repository from the bootstrap module will survive.

## Further Improvements

 - [X] state versioning
 - [X] move all the terraform folder in folder terraform/modules and move bootstrap into terraform/bootstrap
- [ ] codify the GitHub OIDC provider and IAM role in the bootstrap (I did this manually)
- [ ] integrate "curl https://tm.<your-domain>/health" health check into my pipeline
- [ ] store config.yaml in S3 bucket and pass it to the tasks at runtime rather than in the container image to prevent rebuilding and in my case recompressing the image which can make builds longer
- [ ] create scripts to perform checks for ECS and other resources
- [ ] create own provider and module to work with GoDaddy
- [ ] create action to list all resources currently in use on AWS
- [ ] create script to watch ECS service live as tasks are being created and when being destroyed, it would be useful for troubleshooting.
- [ ] create VPC endpoints to lower the costs of NAT gateways
- [ ] enable tagging of resources
- [ ] experiment with FinOps. See what other decisions I can make to cut costs
