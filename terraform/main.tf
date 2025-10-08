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
  target_group_arn = module.resources.target_group_arn
}

module "iam" {
    source = "./iam"
}

module "ecs"{
    source = "./ecs"

    ECS_Agent_Role_ARN = module.iam.ECS_Agent_Role_ARN
    web_asg_arn = module.resources.web_asg_arn
    private_subnets = module.vpc.private_subnet_ids
    target_group_arn = module.resources.target_group_arn
    web_sg_id = module.secgroups.web_sg_id

}

module "resources" {
    source = "./resources"

    vpc_id = module.vpc.vpc_id
    web_sg_id = module.secgroups.web_sg_id
    EC2_Instance_Profile_ARN = module.iam.EC2_Instance_Profile_ARN
    web_ecs_cluster_name = module.ecs.web_ecs_cluster_name
    private_subnets = module.vpc.private_subnet_ids
}

module "secgroups" {
    source = "./secgroups"

    vpc_id = module.vpc.vpc_id

}

module "acm"{
    source = "./acm"
}

module "route53" {
    source = "./route53"

    alb_zone_id = module.alb.alb_zone_id
    alb_url = module.alb.alb_url

}

