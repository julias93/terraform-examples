# Provider
################################
variable "region" {
  type        = string
  default     = "ap-northeast-1"
  description = <<EOT
    (Optional) Region name to deploy to.

    Options:
      - ap-northeast-1 # Tokyo
      - ap-northeast-3 # Osaka

    Default: ap-northeast-1
  EOT

  validation {
    condition     = can(regex("^(ap-northeast-1|ap-northeast-3)$", var.region))
    error_message = <<EOT
    Error: Invalid region name.

    Available Options:
    - ap-northeast-1 # Tokyo
    - ap-northeast-3 # Osaka
    EOT
  }
}

# Tag
################################
variable "env" {
  type        = string
  default     = "dev"
  description = <<EOT
    (Optional) Environment for tag.

    Options:
      - test
      - dev
      - stg
      - prod

    Default: dev
  EOT

  validation {
    condition     = can(regex("^(test|dev|stg|prod)$", var.env))
    error_message = <<EOT
      Error: Invalid environment format.

      Available Options:
        - test
        - dev
        - stg
        - prod
    EOT
  }
}

variable "project" {
  type        = string
  default     = ""
  description = <<EOT
    (Required) Project name for tag.

    Default: undefined
    Example: myproject
  EOT
}

variable "subproject" {
  type        = string
  default     = ""
  description = <<EOT
    (Required) Sub-project name for tag.

    Default: undefined
    Example: mysubproject
  EOT
}

# Prefix
################################
variable "prefix" {
  type        = string
  default     = ""
  description = <<EOT
    (Optional) Name prefix for resource name.

    Default: undefined
    Example: prefix-
  EOT
}

variable "prefix_short" {
  type        = string
  default     = ""
  description = <<EOT
    (Optional) Short form of name prefix for resource name.
               Must be less than or equal to 6.

    Default: undefined
    Example: name-
  EOT

  validation {
    condition     = length(var.prefix_short) <= 6
    error_message = <<EOT
      Error: The lenght of 'prefix_short' must be less than or equal to 6.
    EOT
  }
}

# Codepipeline
################################
variable "repo_service" {
  type        = string
  default     = "Github"
  description = <<EOT
    (Required) Repository service name of your application to deploy.

    Options:
      - Github
      - GithubEnterpriseServer
      - Bitbucket

    Default: Github
  EOT

  validation {
    condition     = can(regex("^(Github|GithubEnterpriseServer|Bitbucket)$", var.repo_service))
    error_message = <<EOT
    Error: Invalid repository service name.

    Available Options:
      - Github
      - GithubEnterpriseServer
      - Bitbucket
    EOT
  }
}

variable "repo_name" {
  type        = string
  description = <<EOT
    (Required) Repository name of your application to deploy.

    Default: undefined
    Example: user/repo
  EOT
}

variable "repo_branch" {
  type        = string
  default     = "main"
  description = <<EOT
    (Required) Branch name of your application to deploy.

    Default: main
  EOT
}
