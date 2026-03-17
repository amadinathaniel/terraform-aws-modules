variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "cluster_name must not be empty."
  }
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

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider (from eks-addons module). Required for External Secrets."
  type        = string
  default     = ""
}

variable "oidc_provider_url" {
  description = "URL of the OIDC provider (from eks-addons module). Required for External Secrets."
  type        = string
  default     = ""
}

# ------------------------------------------------------------------------------
# Addon Toggles
# ------------------------------------------------------------------------------
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
  description = "Secrets Manager path pattern the External Secrets role can access."
  type        = string
  default     = "*"
}

# ------------------------------------------------------------------------------
# Helm Chart Versions
# ------------------------------------------------------------------------------
variable "cluster_autoscaler_version" {
  description = "Helm chart version for Cluster Autoscaler."
  type        = string
  default     = "9.54.0"
}

variable "aws_lbc_version" {
  description = "Helm chart version for AWS Load Balancer Controller."
  type        = string
  default     = "1.17.1"
}

variable "nginx_ingress_version" {
  description = "Helm chart version for Nginx Ingress Controller."
  type        = string
  default     = "4.14.2"
}

variable "cert_manager_version" {
  description = "Helm chart version for Cert Manager."
  type        = string
  default     = "v1.19.2"
}

variable "external_secrets_version" {
  description = "Helm chart version for External Secrets Operator."
  type        = string
  default     = "1.3.2"
}

# ------------------------------------------------------------------------------
# Tags
# ------------------------------------------------------------------------------
variable "common_tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}
