provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

/** Create the subdomain edge.acme-example.com */
module "domain" {
  source           = "git::https://github.com/cloudposse/terraform-aws-route53-cluster-zone.git?ref=master"
  namespace        = "blog"
  stage            = "dev"
  name             = "edge"
  parent_zone_name = "acme-example.com"
  zone_name        = "$${name}.$${parent_zone_name}"
}

/** Create a Lambda@Edge function */
module "security_header_lambda" {
  source                 = "transcend-io/lambda-at-edge/aws"
  version                = "0.0.2"
  name                   = "security_headers"
  description            = "Adds security headers to the response"
  lambda_code_source_dir = "${path.module}/../../src/security_headers"
}

/** Create the S3 bucket with CloudFront distribution necessary to host the site */
module "cloudfront-s3-cdn" {
  source  = "cloudposse/cloudfront-s3-cdn/aws"
  version = "0.34.1"

  name               = "edge-acme-example"
  encryption_enabled = true

  # DNS Settings
  parent_zone_id      = module.domain.zone_id
  acm_certificate_arn = module.acm_request_certificate.arn
  aliases             = [module.domain.zone_name]
  ipv6_enabled        = true

  # Caching Settings
  default_ttl = 300
  compress    = true

  # Website settings
  website_enabled = true
  index_document  = "index.html"
  error_document  = "index.html"

  # Lambda@Edge setup
  lambda_function_association = [
    {
      event_type   = "origin-response"
      include_body = false
      lambda_arn   = module.security_header_lambda.arn
    },
  ]

  depends_on = [module.acm_request_certificate]
}

/** Request an SSL certificate */
module "acm_request_certificate" {
  source                      = "cloudposse/acm-request-certificate/aws"
  version                     = "0.7.0"
  domain_name                 = module.domain.zone_name
  wait_for_certificate_issued = true
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