module "vpc" {
    source = "./vpc"
}

module "alb" {
  source = "./alb"

  public_subnets = module.vpc.public_subnet_ids
  load_balancer_security_group = [module.secgroups.load_balancer_sg_id]
  vpc_id = module.vpc.vpc_id
  internet_gateway_id = module.vpc.internet_gateway_id
  cert_arn = module.acm.cert_arn

}

module "iam" {
    source = "./iam"
}

module "ecs"{
    source = "./ecs"
    vpc_id = module.vpc.vpc_id
    ECS_Agent_Role_ARN = module.iam.ECS_Agent_Role_ARN
    web_asg_arn = module.resources.web_asg_arn
    private_subnets = module.vpc.private_subnet_ids
    target_group_arn = module.alb.target_group_arn
    web_sg_id = module.secgroups.web_sg_id
    hostPort = var.hostPort
    web_ecs_cluster = var.web_ecs_cluster
    containerPort = var.containerPort
    app_name = var.app_name

    depends_on = [
        module.iam
    ]

}

module "resources" {
    source = "./resources"
    vpc_id = module.vpc.vpc_id
    web_sg_id = module.secgroups.web_sg_id
    EC2_Instance_Profile_ARN = module.iam.EC2_Instance_Profile_ARN
    web_ecs_cluster_name = module.ecs.web_ecs_cluster_name
    private_subnets = module.vpc.private_subnet_ids
    target_group_arn = module.alb.target_group_arn
}

module "secgroups" {
    source = "./secgroups"
    vpc_id = module.vpc.vpc_id
    containerPort = var.containerPort
}

module "acm"{
    source = "./acm"
    domain_name = var.domain_name
    route53_record_name = module.route53.route53_record_name
    cert_validation = module.route53.cert_validation
}

module "route53" {
    source = "./route53"
    domain_name = var.domain_name
    alb_zone_id = module.alb.alb_zone_id
    alb_url = module.alb.alb_url
    cert_arn = module.acm.cert_arn
    domain_validation_options = module.acm.domain_validation_options
}

