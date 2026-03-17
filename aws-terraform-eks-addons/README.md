# terraform-aws-eks-addons

Terraform module to install EKS cluster addons and Helm charts with all required IAM roles and policies.

## Addons Available

| Addon | Type | Default | Description |
|-------|------|---------|-------------|
| OIDC Provider | IAM | Enabled | IAM OIDC provider for IRSA |
| Pod Identity Agent | EKS Addon | Disabled | Pod-level IAM credentials |
| EBS CSI Driver | EKS Addon + IAM | Disabled | Persistent volume support with KMS encryption |
| Metrics Server | Helm | Disabled | Required for HPA and Cluster Autoscaler |
| Cluster Autoscaler | Helm + IAM | Disabled | Automatic node scaling |
| AWS Load Balancer Controller | Helm + IAM | Disabled | Kubernetes-native ALB/NLB management |
| Nginx Ingress Controller | Helm | Disabled | Ingress routing via NLB |
| Cert Manager | Helm | Disabled | TLS certificate management |
| External Secrets Operator | Helm + IAM | Disabled | Secrets Manager integration via IRSA |

## Dependency Chain
```
OIDC Provider + Pod Identity Agent
  └── EBS CSI Driver
  └── Metrics Server
        └── Cluster Autoscaler
              └── AWS Load Balancer Controller
                    └── Nginx Ingress Controller
                          └── Cert Manager
  └── External Secrets Operator (requires OIDC Provider)
```

## Usage
```hcl
module "eks_addons" {
  source = "../terraform-aws-modules/aws-terraform-eks-addons"

  cluster_name                       = "teleios-nate-dev-eks"
  cluster_endpoint                   = "https://ABCDEF.gr7.us-east-1.eks.amazonaws.com"
  cluster_certificate_authority_data = "LS0tLS1CRUdJTi..."
  oidc_provider_url                  = "https://oidc.eks.us-east-1.amazonaws.com/id/ABCDEF"
  vpc_id                             = "vpc-123456"
  aws_region                         = "us-east-1"

  enable_oidc_provider      = true
  enable_pod_identity       = true
  enable_ebs_csi_driver     = true
  enable_metrics_server     = true
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
| cluster_endpoint | EKS cluster API endpoint | string | - | yes |
| cluster_certificate_authority_data | Base64-encoded cluster CA cert | string | - | yes |
| oidc_provider_url | OIDC provider URL from EKS cluster | string | - | yes |
| vpc_id | VPC ID (required for AWS LBC) | string | "" | no |
| aws_region | AWS region | string | - | yes |
| enable_oidc_provider | Create IAM OIDC provider | bool | true | no |
| enable_pod_identity | Install Pod Identity Agent | bool | false | no |
| enable_ebs_csi_driver | Install EBS CSI Driver | bool | false | no |
| enable_metrics_server | Install Metrics Server | bool | false | no |
| enable_cluster_autoscaler | Install Cluster Autoscaler | bool | false | no |
| enable_aws_lbc | Install AWS Load Balancer Controller | bool | false | no |
| enable_nginx_ingress | Install Nginx Ingress Controller | bool | false | no |
| enable_cert_manager | Install Cert Manager | bool | false | no |
| enable_external_secrets | Install External Secrets Operator | bool | false | no |
| external_secrets_allowed_secrets_path | Secrets Manager path pattern | string | "*" | no |
| common_tags | Common tags for all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| oidc_provider_arn | OIDC provider ARN |
| oidc_provider_url | OIDC provider URL |
| ebs_csi_driver_role_arn | EBS CSI Driver IAM role ARN |
| cluster_autoscaler_role_arn | Cluster Autoscaler IAM role ARN |
| aws_lbc_role_arn | AWS LBC IAM role ARN |
| external_secrets_role_arn | External Secrets IAM role ARN |

## Preconditions

- `enable_cluster_autoscaler` requires `enable_metrics_server = true`
- `enable_aws_lbc` requires `vpc_id` to be set
- `enable_nginx_ingress` requires `enable_aws_lbc = true`
- `enable_cert_manager` requires `enable_nginx_ingress = true`
- `enable_external_secrets` requires `enable_oidc_provider = true`
- `enable_ebs_csi_driver` pod identity association requires `enable_pod_identity = true`
