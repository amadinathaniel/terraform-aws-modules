output "oidc_provider_arn" {
  description = "ARN of the OIDC provider (if created)."
  value       = length(aws_iam_openid_connect_provider.eks) > 0 ? aws_iam_openid_connect_provider.eks[0].arn : ""
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider (if created)."
  value       = length(aws_iam_openid_connect_provider.eks) > 0 ? aws_iam_openid_connect_provider.eks[0].url : ""
}

output "ebs_csi_driver_role_arn" {
  description = "ARN of the EBS CSI Driver IAM role (if created)."
  value       = length(aws_iam_role.ebs_csi_driver) > 0 ? aws_iam_role.ebs_csi_driver[0].arn : ""
}

output "cluster_autoscaler_role_arn" {
  description = "ARN of the Cluster Autoscaler IAM role (if created)."
  value       = length(aws_iam_role.cluster_autoscaler) > 0 ? aws_iam_role.cluster_autoscaler[0].arn : ""
}

output "aws_lbc_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM role (if created)."
  value       = length(aws_iam_role.aws_lbc) > 0 ? aws_iam_role.aws_lbc[0].arn : ""
}

output "external_secrets_role_arn" {
  description = "ARN of the External Secrets IAM role (if created)."
  value       = length(aws_iam_role.external_secrets) > 0 ? aws_iam_role.external_secrets[0].arn : ""
}
