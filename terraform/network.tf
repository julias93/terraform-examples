locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.0"

  name = "${var.prefix}vpc"
  cidr = "10.0.0.0/16"

  azs            = local.azs
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnet_names = [
    "${var.prefix}public-subnet-${local.azs[0]}",
    "${var.prefix}public-subnet-${local.azs[1]}",
  ]
  private_subnets = ["10.0.64.0/24", "10.0.65.0/24"]
  private_subnet_names = [
    "${var.prefix}private-subnet-${local.azs[0]}",
    "${var.prefix}private-subnet-${local.azs[1]}"
  ]

  intra_subnets = ["10.0.128.0/24", "10.0.129.0/24"]
  intra_subnet_names = [
    "${var.prefix}intra-subnet-${local.azs[0]}",
    "${var.prefix}intra-subnet-${local.azs[1]}"
  ]

  # Single NAT Gateway
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

}

module "ecr_endpoint_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.0"

  name   = "${var.prefix}ecr-endpoint-sg"
  vpc_id = module.vpc.vpc_id
  ingress_with_source_security_group_id = [
    {
      rule                     = "https-443-tcp"
      source_security_group_id = module.ecs_service.security_group_id
    }
  ]
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]
}

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "4.0.0"

  vpc_id = module.vpc.vpc_id

  endpoints = {
    "s3" = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags            = { Name = "${var.prefix}s3-vpc-endpoint" }
    },
    "ecr.dkr" = {
      service            = "ecr.dkr"
      subnet_ids         = [module.vpc.private_subnets[0]]
      security_group_ids = [module.ecr_endpoint_sg.security_group_id]
      tags               = { Name = "${var.prefix}ecr-dkr-vpc-endpoint" }
    },
    "ecr.api" = {
      service            = "ecr.api"
      subnet_ids         = [module.vpc.private_subnets[0]]
      security_group_ids = [module.ecr_endpoint_sg.security_group_id]
      tags               = { Name = "${var.prefix}ecr-api-vpc-endpoint" }
    }
  }
}
