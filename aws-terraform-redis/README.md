# terraform-aws-redis

Terraform module to provision an ElastiCache Redis replication group with a dedicated security group, subnet group, and optional auth token stored in Secrets Manager.

## Features

- ElastiCache Redis replication group with configurable engine version
- Encryption at rest and in transit
- Auto-generated AUTH token stored in Secrets Manager with custom naming (`<replication-group-id>/redis`)
- Secret contains REDIS_PASSWORD, REDIS_HOST, REDIS_PORT
- Automatic failover support (requires 2+ nodes)
- Dedicated security group with ingress from allowed security groups
- Dedicated subnet group

## Usage
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

  subnet_ids                 = ["subnet-abc123", "subnet-def456"]
  vpc_id                     = "vpc-123456"
  allowed_security_group_ids = ["sg-eks-nodes-123", "sg-ec2-web-456"]

  common_tags = {
    Project     = "e-commerce-infrastructure"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| replication_group_id | Replication group ID (max 40 chars) | string | - | yes |
| engine_version | Redis engine version | string | - | yes |
| node_type | ElastiCache node type | string | "cache.t4g.micro" | no |
| num_cache_clusters | Number of cache clusters (1-6) | number | - | yes |
| automatic_failover_enabled | Enable automatic failover (needs 2+ nodes) | bool | false | no |
| transit_encryption_enabled | Enable encryption in transit | bool | true | no |
| at_rest_encryption_enabled | Enable encryption at rest | bool | true | no |
| create_auth_token | Create random AUTH token | bool | true | no |
| subnet_ids | Subnet IDs for cache subnet group | list(string) | - | yes |
| vpc_id | VPC ID for security group | string | - | yes |
| allowed_security_group_ids | SG IDs allowed to access Redis | list(string) | [] | no |
| common_tags | Common tags for all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| replication_group_id | Replication group ID |
| primary_endpoint_address | Primary endpoint address |
| reader_endpoint_address | Reader endpoint address |
| port | Port number |
| security_group_id | Security group ID |
| auth_token | AUTH token (sensitive) |
| auth_token_secret_arn | Secrets Manager secret ARN |
| auth_token_secret_name | Secrets Manager secret name |
