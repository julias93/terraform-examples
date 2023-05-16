locals {
  ecs_container = "app"
}

module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "5.0.0"

  cluster_name = "${var.prefix}ecs-cluster"
  cluster_settings = {
    "name" : "containerInsights",
    "value" : "disabled"
  }

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 1
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 1
      }
    }
  }
}

module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.0.0"

  name        = "${var.prefix}ecs-service"
  cluster_arn = module.ecs_cluster.arn

  cpu    = 1024
  memory = 2048

  subnet_ids       = [module.vpc.private_subnets[0]]
  assign_public_ip = false

  security_group_name = "${var.prefix}ecs-sg"
  security_group_tags = {
    Name = "${var.prefix}ecs-sg"
  }
  security_group_rules = [
    {
      type                     = "ingress"
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      source_security_group_id = module.alb.security_group_id
    },
    {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tasks_iam_role_statements = [
    {
      effect    = "Allow"
      actions   = ["rds:*"]
      resources = ["*"]
    }
  ]
  propagate_tags = "TASK_DEFINITION"
  container_definitions = {
    (local.ecs_container) = {

      cpu       = 512
      memory    = 1024
      essential = true
      image     = "${module.ecr.repository_url}:latest"

      readonly_root_filesystem  = false
      enable_cloudwatch_logging = true
      memory_reservation        = 100

      environment = [
        {
          name  = "RAILS_ENV"
          value = "production"
        },
        {
          name  = "PORT"
          value = "80"
        },
        {
          name  = "RAILS_LOG_TO_STDOUT"
          value = "true"
        },
        {
          name  = "RAILS_SERVE_STATIC_FILES"
          value = "true"
        },
        {
          name  = "DATABASE_HOST"
          value = module.rds.cluster_endpoint
        },
        {
          name  = "DATABASE_NAME"
          value = "${var.prefix}db"
        },
      ]
      secrets = [
        {
          name      = "DATABASE_USER"
          valueFrom = "${module.rds.cluster_master_user_secret[0].secret_arn}:username::"
        },
        {
          name      = "DATABASE_PASSWORD"
          valueFrom = "${module.rds.cluster_master_user_secret[0].secret_arn}:password::"
        },
        {
          name      = "SECRET_KEY_BASE"
          valueFrom = aws_ssm_parameter.rails_master_key.arn
        },
      ]
      port_mappings = [
        {
          name          = "ecs"
          hostPort      = 80
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      health_check = {
        command      = ["CMD-SHELL", "curl -f http://localhost/ || exit 1"]
        interval     = 30
        timeout      = 5
        retries      = 3
        start_period = 60
      }
    }

  }
  load_balancer = {
    app = {
      target_group_arn = module.alb.target_group_arns[0]
      container_name   = "app"
      container_port   = 80
    }
  }
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.prefix}ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

data "aws_iam_policy_document" "ecs_task_policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["rds:*"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ecs_task_policy" {
  role   = aws_iam_role.ecs_task_role.name
  policy = data.aws_iam_policy_document.ecs_task_policy.json
}

# resource "aws_secretsmanager_secret" "rails_master_key" {
#   name = "${var.prefix}rails-master-key"
# }

resource "aws_ssm_parameter" "rails_master_key" {
  name      = "/${var.project}/${var.env}/ecs/rails_master_key"
  type      = "SecureString"
  value     = file("${path.module}/../config/master.key")
  key_id    = "alias/aws/ssm"
  overwrite = true
}
