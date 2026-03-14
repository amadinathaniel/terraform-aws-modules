# terraform-aws-redis

Terraform module to provision an ElastiCache Redis replication group with a dedicated security group and subnet group.

## Features

- ElastiCache Redis replication group with configurable engine version
- Encryption at rest and in transit
- Optional auto-generated AUTH token
- Automatic failover support (requires 2+ nodes)
- Dedicated security group with ingress from allowed security groups
- Dedicated subnet group

## Usage

```hcl
module "redis" {
  source = "./terraform-aws-modules/aws-terraform-redis"

  replication_group_id       = "teleios-nate-dev-redis"
  engine_version             = "7.2"
  node_type                  = "cache.t4g.micro"
  num_cache_clusters         = 1
  automatic_failover_enabled = false

  subnet_ids                 = values(module.vpc.cache_subnet_ids)
  vpc_id                     = module.vpc.vpc_id
  allowed_security_group_ids = [module.eks.node_security_group_id]

  common_tags = var.common_tags
}
```
