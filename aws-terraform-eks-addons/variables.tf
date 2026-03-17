variable "cluster_name" {
  description = "Name of the EKS cluster to install addons into."
  type        = string
  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "cluster_name must not be empty."
  }
}

variable "cluster_endpoint" {
  description = "EKS cluster API endpoint."
  type        = string
}

variable "cluster_certificate_authority_data" {
  description = "Base64-encoded cluster CA certificate."
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL from the EKS cluster."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the AWS Load Balancer Controller."
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWS region for the cluster autoscaler."
  type        = string
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "aws_region must be a valid AWS region format (e.g. us-east-1)."
  }
}

# ------------------------------------------------------------------------------
# Addon Toggles
# ------------------------------------------------------------------------------
variable "enable_oidc_provider" {
  description = "Create the IAM OIDC provider for IRSA."
  type        = bool
  default     = true
}

variable "enable_pod_identity" {
  description = "Install the EKS Pod Identity Agent addon."
  type        = bool
  default     = false
}

variable "enable_ebs_csi_driver" {
  description = "Install the EBS CSI Driver addon with IAM role."
  type        = bool
  default     = false
}

variable "enable_metrics_server" {
  description = "Install Metrics Server via Helm."
  type        = bool
  default     = false
}

variable "enable_cluster_autoscaler" {
  description = "Install Cluster Autoscaler via Helm with IAM role."
  type        = bool
  default     = false
}

variable "enable_aws_lbc" {
  description = "Install AWS Load Balancer Controller via Helm with IAM role."
  type        = bool
  default     = false
}

variable "enable_nginx_ingress" {
  description = "Install Nginx Ingress Controller via Helm."
  type        = bool
  default     = false
}

variable "enable_cert_manager" {
  description = "Install Cert Manager via Helm."
  type        = bool
  default     = false
}

variable "enable_external_secrets" {
  description = "Install External Secrets Operator via Helm with IAM role."
  type        = bool
  default     = false
}

variable "external_secrets_allowed_secrets_path" {
  description = "Secrets Manager path pattern the External Secrets role can access (e.g. myproject/*)."
  type        = string
  default     = "*"
}

# ------------------------------------------------------------------------------
# Tags
# ------------------------------------------------------------------------------
variable "common_tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}
