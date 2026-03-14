# terraform-aws-modules

Enterprise-grade Terraform module library for deploying production-ready AWS infrastructure. Built for the Teleios e-commerce platform to enable standardized, repeatable deployments across dev, staging, and production environments.

## Architecture Overview
```
terraform-aws-modules/
├── terraform-aws-vpc/          VPC, subnets, NAT Gateway, route tables, subnet groups
├── terraform-aws-eks/          EKS cluster, managed node groups, IAM, addons, ALB
├── terraform-aws-ec2/          Launch Templates, Auto Scaling Groups, IAM, security groups
├── terraform-aws-rds/          RDS PostgreSQL, security groups, subnet groups
├── terraform-aws-redis/        ElastiCache Redis replication groups, security groups
└── terraform-aws-s3/           S3 buckets, versioning, encryption, lifecycle policies
```

## Module Summary

| Module | Description | Creates SGs Internally | VPC Dependent |
|--------|-------------|----------------------|---------------|
| `terraform-aws-vpc` | Networking foundation with public, private, database, and cache subnets | N/A | No (is the foundation) |
| `terraform-aws-eks` | EKS cluster with managed node groups, EKS addons, and optional ALB | Yes (cluster + node + ALB) | Yes |
| `terraform-aws-ec2` | EC2 instances via Launch Templates and Auto Scaling Groups | Yes (instance-level) | Yes |
| `terraform-aws-rds` | RDS PostgreSQL with Multi-AZ, encryption, and managed passwords | Yes (database-level) | Yes |
| `terraform-aws-redis` | ElastiCache Redis with replication, encryption, and optional AUTH | Yes (cache-level) | Yes |
| `terraform-aws-s3` | S3 buckets with versioning, SSE, public access block, and lifecycle rules | No (not VPC-bound) | No |

## Dependency Flow
```
VPC (foundation)
 ├── EKS ──── receives VPC ID + private/public subnet IDs
 ├── EC2 ──── receives VPC ID + subnet IDs by tier
 ├── RDS ──── receives VPC ID + database subnet IDs + allowed SGs from EKS/EC2
 └── Redis ── receives VPC ID + cache subnet IDs + allowed SGs from EKS/EC2

S3 (independent — no VPC dependency)
```

## Design Principles

- **Self-contained modules** — each module creates its own security groups, IAM roles, and supporting resources internally. The implementation repo stays thin.
- **`for_each` over `count`** — all resource maps use `for_each` so you can pass `{}` in `.tfvars` to skip creation entirely. `count` is reserved only for boolean toggles (e.g. `allocate_eip`, `single_nat_gateway`, `enable_alb`).
- **No locals** — configuration flows directly from variables to resources for transparency.
- **Security co-located with resources** — security group rules live inside the module that owns the resource, not in a separate module or the implementation repo.

## Naming Convention

All resources follow the pattern:
```
teleios-<name>-<environment>-<resource>
```

Examples: `teleios-nate-dev-vpc`, `teleios-nate-prod-eks`, `teleios-nate-staging-redis`

This is driven by `project_name` and `environment` variables passed from the implementation repo's `.tfvars` files.

## Version Requirements

| Dependency | Version |
|------------|---------|
| Terraform | `>= 1.14` |
| AWS Provider | `~= 6.36` |
| Random Provider | `~> 3.8` (redis module only) |

## Usage with Implementation Repo

These modules are consumed by the [e-commerce-infrastructure-aws](https://github.com/amadinathaniel/e-commerce-infrastructure-aws) implementation repo, which calls each module and provides environment-specific configuration through `.tfvars` files:
```hcl
# Example: vpc.tf in the implementation repo
module "vpc" {
  source = "../terraform-aws-modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  cache_subnet_cidrs    = var.cache_subnet_cidrs
  single_nat_gateway    = var.single_nat_gateway
  cluster_name          = var.cluster_name
  common_tags           = var.common_tags
}
```

## Environment Scaling

| Configuration | Dev | Staging | Prod |
|--------------|-----|---------|------|
| AZs | 2 | 2 | 3 |
| NAT Gateways | 1 (shared) | 1 (shared) | 3 (per-AZ) |
| EKS Nodes | t3.medium, 1–3 | t3.large, 2–5 | t3.xlarge, 3–10 |
| RDS | db.t4g.micro, single-AZ | db.t4g.small, Multi-AZ | db.r6g.large, Multi-AZ |
| Redis | cache.t4g.micro, 1 node | cache.t4g.small, 2 nodes | cache.r6g.large, 3 nodes |
| Backups | 3 days | 7 days | 30 days |

## Cost Management

All resources must be destroyed immediately after verification. The workflow is:

1. `terraform apply -var-file=<env>.tfvars`
2. Verify resources are healthy in the AWS Console
3. Capture screenshots / evidence
4. `terraform destroy -var-file=<env>.tfvars`

Never leave resources running overnight or over weekends.
