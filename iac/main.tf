terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  backend "s3" {
    bucket = "jhilde-tfstate"
    key    = "base"
    region = "us-east-2"
  }

  required_version = ">= 1.2.0"
}


provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "base" {
  bucket = "gha-fun-dev"

  tags = {
    Name        = "Github Actions Fun"
    Environment = "dev"
  }
}

resource "aws_iam_policy" "deploy_policy" {
  name        = "deploypolicy"
  path        = "/"
  description = "My deploy policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Action" : [
          "s3:ListBucket",
          "s3:PutObject"
        ],
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

module "github-oidc" {
  source  = "terraform-module/github-oidc-provider/aws"
  version = "~> 1"

  create_oidc_provider = true
  create_oidc_role     = true

  repositories              = ["jhilde/gha-play"]
  oidc_role_attach_policies = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", aws_iam_policy.deploy_policy.id]
}

resource "aws_s3_bucket_website_configuration" "example" {
  bucket = aws_s3_bucket.base.id

  index_document {
    suffix = "index.html"
  }
}