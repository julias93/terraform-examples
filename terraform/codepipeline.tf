resource "aws_codepipeline" "codepipeline" {
  name     = "${var.prefix}codepipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = module.codepipeline_s3_bucket.s3_bucket_id
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.connection.arn
        FullRepositoryId = var.repo_name
        BranchName       = var.repo_branch
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.codebuild_project.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ClusterName       = module.ecs_cluster.name
        ServiceName       = module.ecs_service.name
        FileName          = "imagedefinitions.json"
        DeploymentTimeout = "15"
      }
    }
  }
}

resource "aws_codestarconnections_connection" "connection" {
  name          = "${var.prefix}connection-${lower(var.repo_service)}"
  provider_type = var.repo_service
}


module "codepipeline_s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.10.0"

  bucket = "${var.prefix}codepipeline-s3-bucket"
  acl    = "private"

  force_destroy = true

  control_object_ownership = true
  object_ownership         = "ObjectWriter"
}

data "aws_iam_policy_document" "codepipeline_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "${var.prefix}codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role.json
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
    ]
    resources = [
      module.codepipeline_s3_bucket.s3_bucket_arn,
      "${module.codepipeline_s3_bucket.s3_bucket_arn}/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["codestar-connections:UseConnection"]
    resources = [aws_codestarconnections_connection.connection.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "${var.prefix}codepipeline-policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}

locals {
  ecs_service_policies = [
    "AmazonECS_FullAccess",
    "AmazonEC2ContainerRegistryFullAccess",
  ]
}

resource "aws_iam_role_policy_attachment" "ecs_service_policy" {
  for_each = toset(local.ecs_service_policies)

  role       = aws_iam_role.codepipeline_role.id
  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
}

output "activate_connection_url" {
  value = "https://${data.aws_region.current.name}.console.aws.amazon.com/codesuite/settings/connections"
}
