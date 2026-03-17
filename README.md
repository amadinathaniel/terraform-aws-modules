# terraform-aws-modules

Enterprise-grade Terraform module library for deploying production-ready AWS infrastructure. Built for the Teleios e-commerce platform to enable standardized, repeatable deployments across dev, staging, and production environments.

## Architecture Overview
```
terraform-aws-modules/
├── aws-terraform-vpc/          VPC, subnets, NAT Gateway, route tables, subnet groups
├── aws-terraform-eks/          EKS cluster, managed node groups, IAM, addons, ALB
├── aws-terraform-eks-addons/   OIDC, Pod Identity, EBS CSI, autoscaler, LBC, ingress, certs, ESO
├── aws-terraform-ec2/          Launch Templates, ASGs, standalone instances, IAM, security groups
├── aws-terraform-rds/          RDS PostgreSQL, security groups, subnet groups, Secrets Manager
├── aws-terraform-redis/        ElastiCache Redis replication groups, security groups, Secrets Manager
└── aws-terraform-s3/           S3 buckets, versioning, encryption, lifecycle policies, bucket policies
```

## Module Summary

| Module | Description | Creates SGs | VPC Dependent |
|--------|-------------|-------------|---------------|
| vpc | Networking foundation with public, private, database, and cache subnets | N/A | No (is the foundation) |
| eks | EKS cluster with managed node groups, EKS core addons, and optional ALB | Yes (cluster + node + ALB) | Yes |
| eks-addons | OIDC provider, Pod Identity, EBS CSI, autoscaler, LBC, ingress, certs, ESO | No (uses EKS cluster SGs) | Yes (LBC needs VPC ID) |
| ec2 | EC2 instances via Launch Templates + ASGs or standalone instances | Yes (instance-level) | Yes |
| rds | RDS PostgreSQL with auto-generated credentials in Secrets Manager | Yes (database-level) | Yes |
| redis | ElastiCache Redis with auto-generated auth token in Secrets Manager | Yes (cache-level) | Yes |
| s3 | S3 buckets with versioning, SSE, public access block, lifecycle rules, bucket policies | No (not VPC-bound) | No |

## Dependency Flow
```
VPC (foundation)
 ├── EKS ──── receives VPC ID + private/public subnet IDs
 │    └── EKS Addons ──── receives cluster name, endpoint, CA data, OIDC URL
 ├── EC2 ──── receives VPC ID + subnet IDs by tier
 ├── RDS ──── receives VPC ID + database subnet IDs + allowed SGs from EKS/EC2
 └── Redis ── receives VPC ID + cache subnet IDs + allowed SGs from EKS/EC2

S3 (independent — no VPC dependency)
```

## Design Principles

- **Self-contained modules** — each module creates its own security groups, IAM roles, and supporting resources internally. The implementation repo stays thin.
- **`for_each` over `count`** — all resource maps use `for_each` so you can pass `{}` in `.tfvars` to skip creation entirely. `count` is reserved only for boolean toggles (e.g. `allocate_eip`, `single_nat_gateway`, `enable_alb`, `use_asg`).
- **No hardcoded values** — everything is configurable through variables. Environments differ only by `.tfvars` files.
- **Security co-located with resources** — security group rules live inside the module that owns the resource, not in a separate module or the implementation repo.
- **Secrets in Secrets Manager** — RDS passwords and Redis auth tokens are auto-generated and stored in Secrets Manager with predictable naming (`<identifier>/postgres`, `<identifier>/redis`).

## Naming Convention

All resources follow the pattern:
```
teleios-<name>-<environment>-<resource>
```

Examples: `teleios-nate-dev-vpc`, `teleios-nate-prod-eks`, `teleios-nate-staging-redis`

This is driven by `project_name` and `environment` variables passed from the implementation repo's `.tfvars` files.

## Secrets Manager Naming

| Secret | Source | Pattern |
|--------|--------|---------|
| RDS credentials | RDS module (auto-generated) | `<identifier>/postgres` |
| Redis auth token | Redis module (auto-generated) | `<identifier>/redis` |
| Data URLs | Implementation repo (built from outputs) | `<project>-<env>-<key>/data-urls` |
| App secrets | Implementation repo (from TFC variables) | `<project>-<env>/<secret-name>` |

## Version Requirements

| Dependency | Version |
|------------|---------|
| Terraform | `>= 1.14` |
| AWS Provider | `~> 6.36` |
| Random Provider | `~> 3.8` (rds, redis modules) |
| Helm Provider | `~> 3.1` (eks-addons module) |
| Kubernetes Provider | `~> 3.0` (eks-addons module) |
| TLS Provider | `~> 4.2` (eks-addons module) |

## Usage with Implementation Repo

These modules are consumed by the [e-commerce-infrastructure-aws](../e-commerce-infrastructure-aws) implementation repo, which calls each module and provides environment-specific configuration through `.tfvars` files.

All customisation happens in tfvars — the implementation repo's `.tf` files are generic pass-throughs that never need editing.
```hcl
# dev.tfvars — everything is controlled here
eks_clusters = {
  eks = {
    cluster_version           = "1.34"
    cluster_log_types         = ["api", "audit", "authenticator"]
    enable_aws_lbc            = true
    enable_nginx_ingress      = true
    enable_cert_manager       = true
    enable_external_secrets   = true
    node_groups = {
      general = {
        instance_types = ["t3.medium"]
        capacity_type  = "ON_DEMAND"
        desired_size   = 2
        min_size       = 1
        max_size       = 10
        disk_size      = 50
        labels         = { workload = "general" }
        taints         = []
      }
    }
  }
}

# Empty map = nothing created
rds_instances = {}
redis_replication_groups = {}
ec2_instances = {}
s3_buckets = {}
```

## Environment Scaling

| Configuration | Dev | Staging | Prod |
|--------------|-----|---------|------|
| AZs | 2 | 2 | 3 |
| NAT Gateways | 1 (shared) | 1 (shared) | 3 (per-AZ) |
| EKS Nodes | t3.medium, 1–3 | t3.large, 2–5 | t3.xlarge, 3–10 |
| RDS | db.t3.micro, single-AZ | db.t4g.small, Multi-AZ | db.r6g.large, Multi-AZ |
| Redis | cache.t4g.micro, 1 node | cache.t4g.small, 2 nodes | cache.r6g.large, 3 nodes |
| Backups | 3 days | 7 days | 30 days |

## Cost Management

All resources must be destroyed immediately after verification. The workflow is:

1. `terraform apply -var-file=<env>.tfvars -var-file=<env>.secret.tfvars`
2. Verify resources are healthy in the AWS Console
3. Capture screenshots / evidence
4. `terraform destroy -var-file=<env>.tfvars -var-file=<env>.secret.tfvars`

Never leave resources running overnight or over weekends.
