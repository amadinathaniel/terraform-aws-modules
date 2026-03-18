# terraform-aws-helm-releases

Terraform module to install Helm charts on EKS with required IAM roles and pod identity associations.

## Charts Available

| Chart | Type | Default | Description |
|-------|------|---------|-------------|
| Cluster Autoscaler | Helm + IAM | Disabled | Automatic node scaling |
| AWS Load Balancer Controller | Helm + IAM | Disabled | Kubernetes-native ALB/NLB management |
| Nginx Ingress Controller | Helm | Disabled | Ingress routing via NLB (IP mode with LBC, instance mode without) |
| Cert Manager | Helm | Disabled | TLS certificate management |
| External Secrets Operator | Helm + IAM | Disabled | Secrets Manager integration via IRSA |
| External DNS | Helm + IAM | Disabled | External DNS (Route53) integration via IRSA |

## Nginx Ingress + LBC Behavior

| LBC Enabled | Load Balancer Type | Target Type | Annotations |
|-------------|-------------------|-------------|-------------|
| Yes | NLB (via LBC) | IP (direct to pod) | `aws-load-balancer-type: external`, `nlb-target-type: ip` |
| No | NLB (in-tree) | Instance (via NodePort) | `aws-load-balancer-type: nlb` |

## Dependency Chain
```
Cluster Autoscaler
  └── AWS Load Balancer Controller (optional)
        └── Nginx Ingress Controller
              └── Cert Manager
External Secrets Operator (independent, requires OIDC)
External DNS (requires OIDC)
```

## Usage
```hcl
module "helm_releases" {
  source = "../terraform-aws-modules/aws-terraform-helm-releases"

  cluster_name      = "teleios-nate-dev-eks"
  vpc_id            = "vpc-123456"
  aws_region        = "us-east-1"
  oidc_provider_arn = "arn:aws:iam::123456789:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/ABCDEF"
  oidc_provider_url = "https://oidc.eks.us-east-1.amazonaws.com/id/ABCDEF"

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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_name | EKS cluster name | string | - | yes |
| vpc_id | VPC ID (required for AWS LBC) | string | "" | no |
| aws_region | AWS region | string | - | yes |
| oidc_provider_arn | OIDC provider ARN (required for External Secrets) | string | "" | no |
| oidc_provider_url | OIDC provider URL (required for External Secrets) | string | "" | no |
| enable_cluster_autoscaler | Install Cluster Autoscaler | bool | false | no |
| enable_aws_lbc | Install AWS Load Balancer Controller | bool | false | no |
| enable_nginx_ingress | Install Nginx Ingress Controller | bool | false | no |
| enable_cert_manager | Install Cert Manager | bool | false | no |
| enable_external_secrets | Install External Secrets Operator | bool | false | no |
| enable_external_dns | Install ExternalDNS via Helm with IAM role | bool | false | no |
| external_dns_domain_filter | Domain to manage | string | "" | no |
| external_secrets_allowed_secrets_path | Secrets Manager path pattern | string | "*" | no |
| cluster_autoscaler_version | Chart version | string | "9.54.0" | no |
| aws_lbc_version | Chart version | string | "1.17.1" | no |
| nginx_ingress_version | Chart version | string | "4.14.2" | no |
| cert_manager_version | Chart version | string | "v1.19.2" | no |
| external_secrets_version | Chart version | string | "1.3.2" | no |
| external_dns_version | Chart version | string | "1.19.0" | no |
| common_tags | Common tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_autoscaler_role_arn | Cluster Autoscaler IAM role ARN |
| aws_lbc_role_arn | AWS LBC IAM role ARN |
| external_secrets_role_arn | External Secrets IAM role ARN |
| nginx_ingress_controller_name | Nginx Ingress Helm release name |
| external_dns_role_arn | ARN of the ExternalDNS IAM role |

## Preconditions

- `enable_aws_lbc` requires `vpc_id` to be set
- `enable_external_secrets` requires `oidc_provider_arn` to be set
