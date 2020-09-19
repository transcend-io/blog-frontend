output s3_bucket {
  description = "Name of the S3 origin bucket"
  value       = module.cloudfront-s3-cdn.s3_bucket
}