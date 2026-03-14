variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  validation {
    condition     = length(var.cluster_name) > 0 && length(var.cluster_name) <= 100
    error_message = "cluster_name must be between 1 and 100 characters."
  }
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.cluster_version))
    error_message = "cluster_version must be in the format X.YY (e.g. 1.34)."
  }
}

variable "cluster_log_types" {
  description = "List of EKS control plane logging types to enable."
  type        = list(string)
  default     = ["api", "audit", "authenticator"]
  validation {
    condition     = alltrue([for t in var.cluster_log_types : contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], t)])
    error_message = "cluster_log_types must only contain: api, audit, authenticator, controllerManager, scheduler."
  }
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be deployed."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the EKS cluster and node groups."
  type        = list(string)
  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "EKS requires at least 2 private subnets in different AZs."
  }
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB."
  type        = list(string)
  default     = []
}

variable "endpoint_public_access" {
  description = "Whether the EKS API server endpoint is publicly accessible."
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Whether the EKS API server endpoint is privately accessible."
  type        = bool
  default     = true
}

variable "node_groups" {
  description = "Map of EKS managed node group definitions."
  type = map(object({
    instance_types = list(string)
    capacity_type  = string
    desired_size   = number
    min_size       = number
    max_size       = number
    disk_size      = number
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  default = {}
}

variable "enable_alb" {
  description = "Whether to create an Application Load Balancer for the EKS cluster."
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}
