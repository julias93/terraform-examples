module "rds" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "8.1.1"

  name           = "${var.prefix}rds"
  engine         = "aurora-mysql"
  instance_class = "db.t3.small"
  instances = {
    1 = {}
  }
  skip_final_snapshot = true

  vpc_id                 = module.vpc.vpc_id
  create_db_subnet_group = true
  db_subnet_group_name   = "${var.prefix}subnet-group"
  subnets                = module.vpc.intra_subnets

  security_group_name = "${var.prefix}rds-sg"
  security_group_tags = {
    #Name = "${var.prefix}rds-sg"
  }
  security_group_rules = [
    {
      type                     = "ingress"
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      source_security_group_id = module.ecs_service.security_group_id
    },
    {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  master_username = "root"
}
