# terraform-aws-s3

Terraform module to provision an S3 bucket with versioning, server-side encryption, lifecycle policies, and public access controls.

## Features

- S3 bucket with versioning enabled by default
- Server-side encryption (AES256 or KMS)
- Public access block (all four settings enabled)
- Configurable lifecycle rules (expiration, transition, multipart cleanup)
- Optional access logging
- Force destroy option for non-production use

## Usage

```hcl
module "s3" {
  source = "./terraform-aws-modules/aws-terraform-s3"

  bucket_name   = "teleios-nate-dev-artifacts"
  force_destroy = true

  lifecycle_rules = [
    {
      id              = "expire-artifacts"
      expiration_days = 30
    }
  ]

  tags = merge(var.common_tags, {
    Purpose = "artifacts"
  })
}
```
