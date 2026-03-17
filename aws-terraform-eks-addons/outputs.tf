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
