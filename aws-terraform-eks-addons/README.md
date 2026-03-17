# terraform-aws-eks-addons

Terraform module to install AWS-native EKS addons with required IAM roles and policies. No Helm or Kubernetes providers required.

## Addons Available

| Addon | Type | Default | Description |
|-------|------|---------|-------------|
| OIDC Provider | IAM | Enabled | IAM OIDC provider for IRSA |
| Pod Identity Agent | EKS Addon | Disabled | Pod-level IAM credentials |
| EBS CSI Driver | EKS Addon + IAM | Disabled | Persistent volume support with KMS encryption |
| Metrics Server | EKS Addon | Disabled | Container resource metrics for HPA and autoscaling |

## Usage
```hcl
module "eks_addons" {
  source = "../terraform-aws-modules/aws-terraform-eks-addons"

  cluster_name      = "teleios-nate-dev-eks"
  oidc_provider_url = "https://oidc.eks.us-east-1.amazonaws.com/id/ABCDEF"

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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_name | EKS cluster name | string | - | yes |
| oidc_provider_url | OIDC provider URL from EKS cluster | string | - | yes |
| enable_oidc_provider | Create IAM OIDC provider | bool | true | no |
| enable_pod_identity | Install Pod Identity Agent | bool | false | no |
| enable_ebs_csi_driver | Install EBS CSI Driver | bool | false | no |
| enable_metrics_server | Install Metrics Server | bool | false | no |
| common_tags | Common tags for all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| oidc_provider_arn | OIDC provider ARN |
| oidc_provider_url | OIDC provider URL |
| ebs_csi_driver_role_arn | EBS CSI Driver IAM role ARN |
