terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.6"
    }
  }
}

locals {
  default_tags = {
    ManagedBy   = "Terraform"
    Project     = var.project
    Environment = var.env
  }
  optional_tags = 1 <= length(var.subproject) && length(var.subproject) >= 6 ? {
    SubProject = var.subproject
  } : {}

  merged_tags = merge(local.default_tags, local.optional_tags)
}

provider "aws" {
  region = var.region
  default_tags {
    tags = local.merged_tags
  }
}
