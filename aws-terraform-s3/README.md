# terraform-aws-s3

Terraform module to provision an S3 bucket with versioning, server-side encryption, lifecycle policies, bucket policies, and public access controls.

## Features

- S3 bucket with configurable versioning (disabled by default)
- Server-side encryption (AES256 or KMS)
- Public access block (all four settings enabled by default)
- Configurable lifecycle rules (expiration, transition, multipart cleanup)
- Optional bucket policy
- Optional access logging
- Force destroy option for non-production use

## Usage
```hcl
module "s3" {
  source = "../terraform-aws-modules/aws-terraform-s3"

  bucket_name        = "teleios-nate-dev-artifacts"
  force_destroy      = true
  versioning_enabled = false

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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| bucket_name | Name of the S3 bucket | string | - | yes |
| force_destroy | Force destroy bucket and all objects | bool | false | no |
| versioning_enabled | Enable versioning on the bucket | bool | false | no |
| sse_algorithm | Encryption algorithm (AES256 or aws:kms) | string | "AES256" | no |
| kms_key_id | KMS key ID (required if sse_algorithm is aws:kms) | string | null | no |
| lifecycle_rules | List of lifecycle rule configurations | list(object) | [] | no |
| bucket_policy | JSON bucket policy to attach | string | null | no |
| logging | Access logging configuration | object | null | no |
| tags | Tags for the bucket | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | Name of the S3 bucket |
| bucket_arn | ARN of the S3 bucket |
| bucket_domain_name | Domain name of the S3 bucket |
| bucket_regional_domain_name | Regional domain name of the S3 bucket |
