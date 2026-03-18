variable "replication_group_id" {
  description = "ID of the ElastiCache replication group."
  type        = string
  validation {
    condition     = length(var.replication_group_id) > 0 && length(var.replication_group_id) <= 40
    error_message = "replication_group_id must be between 1 and 40 characters."
  }
}

variable "engine_version" {
  description = "Redis engine version."
  type        = string
  validation {
    condition     = length(var.engine_version) > 0
    error_message = "engine_version must not be empty."
  }
}

variable "node_type" {
  description = "ElastiCache node type."
  type        = string
  default     = "cache.t4g.micro"
}

variable "num_cache_clusters" {
  description = "Number of cache clusters (nodes) in the replication group."
  type        = number
  validation {
    condition     = var.num_cache_clusters >= 1 && var.num_cache_clusters <= 6
    error_message = "num_cache_clusters must be between 1 and 6."
  }
}

variable "automatic_failover_enabled" {
  description = "Whether automatic failover is enabled (requires num_cache_clusters >= 2)."
  type        = bool
  default     = false
}

variable "multi_az_enabled" {
  description = "Whether to enable Multi-AZ for the replication group (requires automatic_failover_enabled and num_cache_clusters >= 2)."
  type        = bool
  default     = false
}

variable "transit_encryption_enabled" {
  description = "Whether to enable encryption in transit."
  type        = bool
  default     = true
}

variable "at_rest_encryption_enabled" {
  description = "Whether to enable encryption at rest."
  type        = bool
  default     = true
}

variable "create_auth_token" {
  description = "Whether to create a random AUTH token for Redis."
  type        = bool
  default     = true
}

variable "subnet_ids" {
  description = "List of subnet IDs for the cache subnet group."
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for the security group."
  type        = string
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs allowed to access Redis."
  type        = map(string)
  default     = {}
}

variable "common_tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}
