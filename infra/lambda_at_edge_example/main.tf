provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

/** Create a Lambda@Edge function */
module "security_header_lambda" {
  source                 = "transcend-io/lambda-at-edge/aws"
  version                = "0.0.2"
  name                   = "security_headers"
  description            = "Adds security headers to the response"
  runtime                = "nodejs12.x"
  lambda_code_source_dir = "${path.module}/../../src/security_headers/dist"
}

/** Create the S3 bucket with CloudFront distribution necessary to host the site */
module "cloudfront-s3-cdn" {
  source  = "cloudposse/cloudfront-s3-cdn/aws"
  version = "0.34.1"

  name               = "edge-acme-example"
  encryption_enabled = true

  # Caching Settings
  default_ttl = 300
  compress    = true

  # Website settings
  website_enabled = true
  index_document  = "index.html"
  error_document  = "index.html"

  # Lambda@Edge setup
  lambda_function_association = [{
    event_type   = "origin-response"
    include_body = false
    lambda_arn   = module.security_header_lambda.arn
  }]
}

/** Use remote state through terraform cloud */
terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "transcend-io"

    workspaces {
      name = "edge-blog-frontend"
    }
  }
}