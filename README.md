# terraform-aws-modules

Enterprise-grade Terraform module library for deploying production-ready AWS infrastructure. Built for the Teleios e-commerce platform to enable standardized, repeatable deployments across dev, staging, and production environments.

## Architecture Overview
```
terraform-aws-modules/
├── aws-terraform-vpc/              VPC, subnets, NAT Gateway, route tables, subnet groups
├── aws-terraform-eks/              EKS cluster, managed node groups, IAM, core addons, ALB
├── aws-terraform-eks-addons/       OIDC, Pod Identity, EBS CSI Driver, Metrics Server
├── aws-terraform-helm-releases/    Autoscaler, AWS LBC, Nginx Ingress, Cert Manager, ESO
├── aws-terraform-ec2/              Launch Templates, ASGs, standalone instances, IAM, security groups
├── aws-terraform-rds/              RDS PostgreSQL, security groups, subnet groups, Secrets Manager
├── aws-terraform-redis/            ElastiCache Redis replication groups, security groups, Secrets Manager
└── aws-terraform-s3/               S3 buckets, versioning, encryption, lifecycle policies, bucket policies
```

## Module Summary

| Module | Description | Providers | Creates SGs |
|--------|-------------|-----------|-------------|
| vpc | Networking foundation with public, private, database, and cache subnets | AWS | No |
| eks | EKS cluster with managed node groups, core EKS addons, and optional ALB | AWS | Yes |
| eks-addons | OIDC provider, Pod Identity, EBS CSI Driver, Metrics Server | AWS, TLS | No |
| helm-releases | Cluster Autoscaler, AWS LBC, Nginx Ingress, Cert Manager, External Secrets | AWS, Helm | No |
| ec2 | EC2 instances via Launch Templates + ASGs or standalone instances | AWS | Yes |
| rds | RDS PostgreSQL with auto-generated credentials in Secrets Manager | AWS, Random | Yes |
| redis | ElastiCache Redis with auto-generated auth token in Secrets Manager | AWS, Random | Yes |
| s3 | S3 buckets with versioning, SSE, public access block, lifecycle rules | AWS | No |

## Dependency Flow
```
VPC (foundation)
 ├── EKS ──── receives VPC ID + private/public subnet IDs
 │    ├── EKS Addons ──── receives cluster name + OIDC URL
 │    └── Helm Releases ── receives cluster name + OIDC ARN/URL from addons
 ├── EC2 ──── receives VPC ID + subnet IDs by tier
 ├── RDS ──── receives VPC ID + database subnet IDs + allowed SGs from EKS/EC2
 └── Redis ── receives VPC ID + cache subnet IDs + allowed SGs from EKS/EC2

S3 (independent — no VPC dependency)
```

## Design Principles

- **Self-contained modules** — each module creates its own security groups, IAM roles, and supporting resources internally. The implementation repo stays thin.
- **`for_each` over `count`** — all resource maps use `for_each` so you can pass `{}` in `.tfvars` to skip creation entirely. `count` is reserved only for boolean toggles.
- **No hardcoded values** — everything is configurable through variables. Environments differ only by `.tfvars` files.
- **Security co-located with resources** — security group rules live inside the module that owns the resource.
- **Secrets in Secrets Manager** — RDS passwords and Redis auth tokens are auto-generated and stored with predictable naming.
- **Provider separation** — EKS addons (AWS-native) and Helm releases are in separate modules so the addons module needs no Helm or Kubernetes providers.

## Naming Convention

All resources follow the pattern:
```
teleios-<name>-<environment>-<resource>
```

Examples: `teleios-nate-dev-vpc`, `teleios-nate-prod-eks`, `teleios-nate-staging-redis`

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
| Random Provider | `~> 3.8` (rds, redis) |
| Helm Provider | `~> 3.1` (helm-releases) |
| TLS Provider | `~> 4.2` (eks-addons) |

## Nginx Ingress + Load Balancer Behavior

| LBC Enabled | Load Balancer | Target Type | Traffic Path |
|-------------|--------------|-------------|-------------|
| Yes | NLB via LBC | IP | Client → NLB → Pod |
| No | NLB in-tree | Instance | Client → NLB → NodePort → Pod |

## Module Usage

Each module is standalone and can be used independently. Below are examples for each module.

### VPC
```hcl
module "vpc" {
  source = "../terraform-aws-modules/aws-terraform-vpc"

  project_name       = "teleios-nate"
  environment        = "dev"
  cluster_names      = ["teleios-nate-dev-eks"]
  vpc_cidr           = "10.10.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  public_subnet_cidrs   = ["10.10.0.0/24", "10.10.1.0/24"]
  private_subnet_cidrs  = ["10.10.10.0/24", "10.10.11.0/24"]
  database_subnet_cidrs = ["10.10.20.0/24", "10.10.21.0/24"]
  cache_subnet_cidrs    = ["10.10.30.0/24", "10.10.31.0/24"]

  single_nat_gateway = true

  common_tags = {
    Project     = "e-commerce-infrastructure"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

### EKS
```hcl
module "eks_cluster" {
  source = "../terraform-aws-modules/aws-terraform-eks"

  cluster_name       = "teleios-nate-dev-eks"
  cluster_version    = "1.34"
  cluster_log_types  = ["api", "audit", "authenticator"]
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = values(module.vpc.private_subnet_ids)
  public_subnet_ids  = values(module.vpc.public_subnet_ids)
  enable_alb         = false

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

  common_tags = {
    Project     = "e-commerce-infrastructure"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

### EKS Addons (AWS-native, no Helm required)
```hcl
module "eks_addons" {
  source = "../terraform-aws-modules/aws-terraform-eks-addons"

  cluster_name      = module.eks_cluster.cluster_name
  oidc_provider_url = module.eks_cluster.cluster_oidc_issuer_url

  enable_oidc_provider  = true
  enable_pod_identity   = true
  enable_ebs_csi_driver = true
  enable_metrics_server = true

  common_tags = {
    Project     = "e-commerce-infrastructure"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

### Helm Releases
```hcl
module "helm_releases" {
  source = "../terraform-aws-modules/aws-terraform-helm-releases"

  cluster_name      = module.eks_cluster.cluster_name
  vpc_id            = module.vpc.vpc_id
  aws_region        = "us-east-1"
  oidc_provider_arn = module.eks_addons.oidc_provider_arn
  oidc_provider_url = module.eks_cluster.cluster_oidc_issuer_url

  enable_cluster_autoscaler = true
  enable_aws_lbc            = true
  enable_nginx_ingress      = true
  enable_cert_manager       = true
  enable_external_secrets   = true

  external_secrets_allowed_secrets_path = "teleios-nate-dev/*"

  common_tags = {
    Project     = "e-commerce-infrastructure"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

### EC2
```hcl
module "ec2" {
  source = "../terraform-aws-modules/aws-terraform-ec2"

  instance_name               = "teleios-nate-dev-web"
  instance_type               = "t3.micro"
  vpc_id                      = module.vpc.vpc_id
  subnet_ids                  = values(module.vpc.public_subnet_ids)
  associate_public_ip_address = true
  use_asg                     = true
  desired_capacity            = 1
  min_size                    = 0
  max_size                    = 2

  ingress_rules = {
    http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow HTTP"
    }
  }

  common_tags = {
    Project     = "e-commerce-infrastructure"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

### RDS
```hcl
module "rds" {
  source = "../terraform-aws-modules/aws-terraform-rds"

  identifier          = "teleios-nate-dev-app"
  db_name             = "appdb"
  username            = "appadmin"
  engine_version      = "16.6"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  backup_retention_period = 3

  subnet_ids                 = values(module.vpc.database_subnet_ids)
  vpc_id                     = module.vpc.vpc_id
  allowed_security_group_ids = [module.eks_cluster.node_security_group_id]

  common_tags = {
    Project     = "e-commerce-infrastructure"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

### Redis
```hcl
module "redis" {
  source = "../terraform-aws-modules/aws-terraform-redis"

  replication_group_id       = "teleios-nate-dev-redis"
  engine_version             = "7.1"
  node_type                  = "cache.t4g.micro"
  num_cache_clusters         = 1
  automatic_failover_enabled = false
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
  create_auth_token          = true

  subnet_ids                 = values(module.vpc.cache_subnet_ids)
  vpc_id                     = module.vpc.vpc_id
  allowed_security_group_ids = [module.eks_cluster.node_security_group_id]

  common_tags = {
    Project     = "e-commerce-infrastructure"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

### S3
```hcl
module "s3" {
  source = "../terraform-aws-modules/aws-terraform-s3"

  bucket_name        = "teleios-nate-dev-artifacts-001"
  force_destroy      = true
  versioning_enabled = false
  sse_algorithm      = "AES256"

  lifecycle_rules = [{
    id              = "expire-artifacts"
    expiration_days = 30
  }]

  common_tags = {
    Project     = "e-commerce-infrastructure"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

## Implementation Repo Pattern

The [e-commerce-infrastructure-aws](https://github.com/amadinathaniel/e-commerce-infrastructure-aws) repo wraps these modules with `for_each`, so everything is driven from `.tfvars`:
```hcl
# eks.tf — generic pass-through, never needs editing
module "eks_cluster" {
  for_each = var.eks_clusters
  source   = "../terraform-aws-modules/aws-terraform-eks"

  cluster_name    = "${var.project_name}-${var.environment}-${each.key}"
  cluster_version = each.value.cluster_version
  # ...
}
```
```hcl
# dev.tfvars — all customisation happens here
eks_clusters = {
  eks = {
    cluster_version       = "1.34"
    enable_aws_lbc        = true
    enable_nginx_ingress  = true
    enable_external_secrets = true
    node_groups = {
      general = {
        instance_types = ["t3.medium"]
        desired_size   = 2
        min_size       = 0
        max_size       = 10
        # ...
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

All resources must be destroyed immediately after verification:

1. `terraform apply -var-file=<env>.tfvars -var-file=<env>.secret.tfvars`
2. Verify resources in AWS Console
3. `terraform destroy -var-file=<env>.tfvars -var-file=<env>.secret.tfvars`
