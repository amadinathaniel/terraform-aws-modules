# terraform-aws-rds

Terraform module to provision an RDS PostgreSQL instance with a dedicated security group, subnet group, and auto-generated credentials stored in Secrets Manager.

## Features

- RDS PostgreSQL with configurable version and instance class
- Auto-generated master password stored in Secrets Manager with custom naming (`<identifier>/postgres`)
- Secret contains POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_HOST, POSTGRES_PORT, POSTGRES_DB
- GP3 encrypted storage with auto-scaling
- Multi-AZ support for high availability
- Automated backups with configurable retention
- Performance Insights (optional)
- Security group with ingress rules for allowed security groups

## Usage
```hcl
module "rds" {
  source = "../terraform-aws-modules/aws-terraform-rds"

  identifier     = "teleios-nate-dev-rds"
  db_name        = "appdb"
  username       = "appadmin"
  engine_version = "16.6"
  instance_class = "db.t4g.micro"

  allocated_storage       = 20
  max_allocated_storage   = 100
  multi_az                = false
  backup_retention_period = 3

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
| identifier | Unique RDS instance identifier | string | - | yes |
| db_name | Default database name | string | - | yes |
| username | Master username | string | - | yes |
| engine_version | PostgreSQL engine version | string | - | yes |
| instance_class | RDS instance class | string | - | yes |
| allocated_storage | Storage in GB | number | - | yes |
| max_allocated_storage | Max storage for autoscaling in GB | number | 100 | no |
| multi_az | Enable Multi-AZ | bool | false | no |
| backup_retention_period | Backup retention in days (0-35) | number | - | yes |
| deletion_protection | Enable deletion protection | bool | false | no |
| performance_insights_enabled | Enable Performance Insights | bool | false | no |
| subnet_ids | Subnet IDs for DB subnet group | list(string) | - | yes |
| vpc_id | VPC ID for security group | string | - | yes |
| allowed_security_group_ids | SG IDs allowed to access the database | list(string) | [] | no |
| common_tags | Common tags for all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| db_instance_id | RDS instance ID |
| db_instance_endpoint | Connection endpoint (host:port) |
| db_instance_address | Hostname |
| db_instance_port | Port number |
| db_instance_arn | RDS instance ARN |
| db_name | Default database name |
| security_group_id | Security group ID |
| master_password_secret_arn | Secrets Manager secret ARN |
| master_password_secret_name | Secrets Manager secret name |
| master_username | Master username |
| master_password | Master password (sensitive) |
