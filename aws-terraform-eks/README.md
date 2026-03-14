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

## Usage

```hcl
module "eks" {
  source = "./terraform-aws-modules/aws-terraform-eks"

  cluster_name       = "teleios-nate-dev-eks"
  cluster_version    = "1.34"
  cluster_log_types  = ["api", "audit", "authenticator"]
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = values(module.vpc.private_subnet_ids)
  public_subnet_ids  = values(module.vpc.public_subnet_ids)
  enable_alb         = true

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

  common_tags = var.common_tags
}
```
