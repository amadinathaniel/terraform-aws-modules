# terraform-aws-eks

Terraform module to provision an EKS cluster with managed node groups, IAM roles, security groups, EKS addons, and an optional Application Load Balancer.

## Features

- EKS cluster with configurable Kubernetes version
- Managed node groups via `for_each` (empty map = no nodes)
- IAM roles for cluster and nodes with required AWS managed policies
- Dedicated security groups for cluster and node communication
- EKS addons: vpc-cni, coredns, kube-proxy
- Optional ALB with HTTP listener and target group
- Control plane logging configuration
- Autoscaler-friendly (ignores desired_size drift on node groups)

## Usage
```hcl
module "eks" {
  source = "../terraform-aws-modules/aws-terraform-eks"

  cluster_name       = "teleios-nate-dev-eks"
  cluster_version    = "1.34"
  cluster_log_types  = ["api", "audit", "authenticator"]
  vpc_id             = "vpc-123456"
  private_subnet_ids = ["subnet-priv1", "subnet-priv2"]
  public_subnet_ids  = ["subnet-pub1", "subnet-pub2"]
  enable_alb         = false

  node_groups = {
    general = {
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      desired_size   = 2
      min_size       = 1
      max_size       = 3
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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_name | EKS cluster name (max 100 chars) | string | - | yes |
| cluster_version | Kubernetes version (e.g. 1.34) | string | - | yes |
| cluster_log_types | Control plane log types | list(string) | ["api","audit","authenticator"] | no |
| vpc_id | VPC ID | string | - | yes |
| private_subnet_ids | Private subnet IDs (min 2) | list(string) | - | yes |
| public_subnet_ids | Public subnet IDs for ALB | list(string) | [] | no |
| endpoint_public_access | Public API endpoint | bool | true | no |
| endpoint_private_access | Private API endpoint | bool | true | no |
| node_groups | Map of node group definitions | map(object) | {} | no |
| enable_alb | Create ALB for the cluster | bool | false | no |
| common_tags | Common tags for all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_name | EKS cluster name |
| cluster_endpoint | API server endpoint |
| cluster_certificate_authority_data | CA certificate data |
| cluster_arn | EKS cluster ARN |
| cluster_security_group_id | Cluster control plane SG ID |
| node_security_group_id | Worker node SG ID |
| cluster_oidc_issuer_url | OIDC provider URL |
| node_group_arns | Map of node group name to ARN |
| cluster_role_arn | Cluster IAM role ARN |
| node_role_arn | Node IAM role ARN |
| alb_arn | ALB ARN (if enabled) |
| alb_dns_name | ALB DNS name (if enabled) |
