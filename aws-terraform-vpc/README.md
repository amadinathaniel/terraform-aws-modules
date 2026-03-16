# terraform-aws-vpc

Terraform module to create an AWS VPC with public, private, database, and cache subnets across multiple availability zones.

## Features

- Configurable CIDR blocks for VPC and all subnet tiers
- Public subnets with Internet Gateway routing
- Private subnets with NAT Gateway routing (single or per-AZ)
- Dedicated database and cache subnet tiers (optional)
- DB and ElastiCache subnet groups created automatically
- Kubernetes discovery tags for EKS integration
- Cost-saving single NAT Gateway option for non-production

## Usage

```hcl
module "vpc" {
  source = "../terraform-aws-modules/aws-terraform-vpc"

  project_name       = var.project_name
  environment        = var.environment
  cluster_name       = length(var.eks_clusters) > 0 ? "${var.project_name}-${var.environment}-${keys(var.eks_clusters)[0]}" : ""
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones

  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  cache_subnet_cidrs    = var.cache_subnet_cidrs

  single_nat_gateway = var.single_nat_gateway
  common_tags        = var.common_tags
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Project name for resource naming | string | - | yes |
| environment | Environment name | string | - | yes |
| vpc_cidr | CIDR block for the VPC | string | - | yes |
| availability_zones | List of AZs | list(string) | - | yes |
| public_subnet_cidrs | Public subnet CIDRs per AZ | list(string) | - | yes |
| private_subnet_cidrs | Private subnet CIDRs per AZ | list(string) | - | yes |
| database_subnet_cidrs | Database subnet CIDRs per AZ | list(string) | {} | no |
| cache_subnet_cidrs | Cache subnet CIDRs per AZ | list(string) | {} | no |
| single_nat_gateway | Use single NAT Gateway | bool | true | no |
| cluster_name | EKS cluster name for subnet tags | string | "" | no |
| common_tags | Common tags for all resources | list(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | VPC ID |
| vpc_cidr_block | VPC CIDR block |
| public_subnet_ids | Map of AZ to public subnet ID |
| private_subnet_ids | Map of AZ to private subnet ID |
| database_subnet_ids | Map of AZ to database subnet ID |
| cache_subnet_ids | Map of AZ to cache subnet ID |
| db_subnet_group_name | DB subnet group name |
| elasticache_subnet_group_name | ElastiCache subnet group name |
