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

output "nginx_ingress_controller_name" {
  description = "Name of the Nginx Ingress Helm release (if created)."
  value       = length(helm_release.nginx_ingress) > 0 ? helm_release.nginx_ingress[0].name : ""
}

output "external_dns_role_arn" {
  description = "ARN of the ExternalDNS IAM role (if created)."
  value       = length(aws_iam_role.external_dns) > 0 ? aws_iam_role.external_dns[0].arn : ""
}
