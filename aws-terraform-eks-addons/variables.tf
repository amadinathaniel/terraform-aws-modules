variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "cluster_name must not be empty."
  }
}

variable "oidc_provider_url" {
  description = "OIDC provider URL from the EKS cluster."
  type        = string
}

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
  description = "Install Metrics Server as an EKS community addon."
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}
