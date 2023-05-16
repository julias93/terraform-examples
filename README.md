# README

This is a sample program to deploy rails app to AWS.

## Reqiremsnts

- Apple Silicon Mac
- Terraform
  - [Install Terraform | Hashicorp](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- AWS CLI v2
  - [Installing or updating the latest version of the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
  - Setup
    - [IAM ユーザーの認証情報を使用した認証](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/cli-authentication-user.html)
    - [MFA トークンを使用して、AWS CLI を通じて AWS リソースへのアクセスを認証するにはどうすればよいですか?](https://repost.aws/ja/knowledge-center/authenticate-mfa-cli)
- Docker
  - [Mac に Docker Desktop をインストール](https://docs.docker.jp/docker-for-mac/install.html)

## Program Overview

### Rails

- Program Root Directory: `.` (Here)
- Database:
  - Engine: MySQL
  - Table: posts
- Web Endpoint:
  - `/`
  - `/posts`

### Terraform

- Program Root Directory: `./terraform`
- Infra
  - ALB: Load Balancer
  - ECS(Fargate): Container runner
  - ECR: Container Registory
  - RDS(Aurora MySQL Compatibility): Database
  - CodePipeline: CI/CD

## Local Development

```bash
# Clone this repository
git clone https://github.com/julias93/aws-rails

# Go into the repository
cd aws-rails

# Copy env file
cp .env.example .env

# Edit env file as you like
vim .env

# Run docker containers
docker compose up -d --buiild
```

Then, access to pages in your browser.

- [http://localhost/](http://localhost/)
- [http://localhost/posts](http://localhost/posts)

## Deploy to AWS

Before running Terraform, you will need to setup your AWS credentials.
You can do this by setting the `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_REGION` environment variables,
or by using the AWS CLI.

```bash
# Move directory to terraform
cd terraform

# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform variables
vim terraform.tfvars

# Initialize terraform
terraform init

# Validate terraform files
terraform validate

# Plan the deployment
terraform plan

# Apply the deployment, it may take 15 minutes
terraform apply
```

This is sample output from `terraform apply`.

```log
...
Outputs:

activate_connection_url = "https://ap-northeast-1.console.aws.amazon.com/codesuite/settings/connections"
service_url = "http://yourappname.ap-northeast-1.elb.amazonaws.com/"
```

Access `active_connection_url` and activate the connection between AWS CodePipeline and Git Repository (e.g.Github).
If the connection is successful, CodePipeline will start.
After deployment is complete, you can access to the `service_url`.

## Coustomize your rails app to terraform

```bash
# Move to this repository root, If you are in terraform directory
cd ..

# Copy terraform directory to your rails app
cp -r terraform /path/to/your-rails-app/

# Copy buildspec.yml to your rails app
cp buildspec.yml /path/to/your-rails-app/

# Move to terraform direcory in your rails app
cd /path/to/your-rails-app/terraform

# Edit your build-time environment variables
vim codebuild.tf
vim ../buildspec.yml

# Edit your run-time environment variables
vim ecs.tf

# Edit terraform variables
vim terraform.tfvars

# Initialize terraform
terraform init

# Validate terraform files
terraform validate

# Plan the deployment
terraform plan

# Apply the deployment, it may take 15 minutes
terraform apply
```
