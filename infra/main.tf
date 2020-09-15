provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

locals {
  domain = "acme-example.com"
}

/** Create the S3 bucket with CloudFront distribution necessary to host the site */
module "cloudfront-s3-cdn" {
  source  = "cloudposse/cloudfront-s3-cdn/aws"
  version = "0.34.1"

  name               = "acme-example"
  encryption_enabled = true

  # DNS Settings
  parent_zone_id      = data.aws_route53_zone.zone.id
  acm_certificate_arn = module.acm_request_certificate.arn
  aliases             = [local.domain]
  ipv6_enabled        = true

  # Caching Settings
  default_ttl = 300
  compress    = true

  # Website settings
  website_enabled = true
  index_document  = "index.html"
  error_document  = "index.html"
}

/** Request an SSL certificate */
module "acm_request_certificate" {
  source                      = "cloudposse/acm-request-certificate/aws"
  version                     = "0.7.0"
  domain_name                 = local.domain
  wait_for_certificate_issued = true
}

/** Lookup our hosted zone for our domain */
data "aws_route53_zone" "zone" {
  name = local.domain
}

/** Use remote state through terraform cloud */
terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "transcend-io"

    workspaces {
      name = "blog-frontend"
    }
  }
}