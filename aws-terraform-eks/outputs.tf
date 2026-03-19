output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Endpoint URL for the EKS cluster API server."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate data for the cluster."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_arn" {
  description = "ARN of the EKS cluster."
  value       = aws_eks_cluster.this.arn
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster control plane."
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS worker nodes."
  value       = aws_security_group.node.id
}

output "cluster_oidc_issuer_url" {
  description = "OIDC provider URL for the EKS cluster."
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "node_group_arns" {
  description = "Map of node group name to node group ARN."
  value       = { for k, v in aws_eks_node_group.this : k => v.arn }
}

output "cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role."
  value       = aws_iam_role.cluster.arn
}

output "node_role_arn" {
  description = "ARN of the EKS node IAM role."
  value       = aws_iam_role.node.arn
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer (if enabled)."
  value       = length(aws_lb.this) > 0 ? aws_lb.this[0].arn : ""
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer (if enabled)."
  value       = length(aws_lb.this) > 0 ? aws_lb.this[0].dns_name : ""
}

output "cluster_primary_security_group_id" {
  description = "EKS-managed cluster security group ID (automatically attached to nodes)."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}
