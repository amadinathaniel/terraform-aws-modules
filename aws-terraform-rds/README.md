# terraform-aws-rds

Terraform module to provision an RDS PostgreSQL instance with a dedicated security group and subnet group.

## Features

- RDS PostgreSQL with configurable version and instance class
- AWS-managed master password (Secrets Manager)
- GP3 encrypted storage with auto-scaling
- Multi-AZ support for high availability
- Automated backups with configurable retention
- Performance Insights (optional)
- Security group with ingress rules for allowed security groups

## Usage

```hcl
module "rds" {
  source = "./terraform-aws-modules/aws-terraform-rds"

  identifier    = "teleios-nate-dev-rds"
  db_name       = "appdb"
  username      = "appadmin"
  instance_class = "db.t4g.micro"

  subnet_ids                 = values(module.vpc.database_subnet_ids)
  vpc_id                     = module.vpc.vpc_id
  allowed_security_group_ids = [module.eks.node_security_group_id]

  common_tags = var.common_tags
}
```
