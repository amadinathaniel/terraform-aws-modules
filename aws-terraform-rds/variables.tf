variable "identifier" {
  description = "Unique identifier for the RDS instance."
  type        = string
  validation {
    condition     = length(var.identifier) > 0 && length(var.identifier) <= 63
    error_message = "identifier must be between 1 and 63 characters."
  }
}

variable "db_name" {
  description = "Name of the default database to create."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9]*$", var.db_name))
    error_message = "db_name must start with a letter and contain only alphanumeric characters."
  }
}

variable "username" {
  description = "Master username for the database."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.username)) && length(var.username) <= 63
    error_message = "username must start with a letter, contain only alphanumerics/underscores, and be at most 63 characters."
  }
}

variable "engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  validation {
    condition     = length(var.engine_version) > 0
    error_message = "engine_version must not be empty."
  }
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
}

variable "allocated_storage" {
  description = "Allocated storage in GB."
  type        = number
  validation {
    condition     = var.allocated_storage >= 20
    error_message = "allocated_storage must be at least 20 GB for RDS PostgreSQL."
  }
}

variable "max_allocated_storage" {
  description = "Maximum storage for autoscaling in GB."
  type        = number
  default     = 100
}

variable "multi_az" {
  description = "Whether to enable Multi-AZ deployment."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups."
  type        = number
  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "backup_retention_period must be between 0 and 35 days."
  }
}

variable "deletion_protection" {
  description = "Whether deletion protection is enabled."
  type        = bool
  default     = false
}

variable "performance_insights_enabled" {
  description = "Whether Performance Insights is enabled."
  type        = bool
  default     = false
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group."
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for the security group."
  type        = string
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs allowed to access the database."
  type        = map(string)
  default     = {}
}

variable "common_tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}
