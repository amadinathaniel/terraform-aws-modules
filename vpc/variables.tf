variable "project_name" {
  description = "Project name used for resource naming."
  type        = string
  validation {
    condition     = length(var.project_name) > 0
    error_message = "project_name must not be empty."
  }
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)."
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block (e.g. 10.10.0.0/16)."
  }
}

variable "availability_zones" {
  description = "List of availability zones to deploy subnets into."
  type        = list(string)
  validation {
    condition     = length(var.availability_zones) >= 1
    error_message = "At least one availability zone must be specified."
  }
}

variable "public_subnet_cidrs" {
  description = "Map of availability zone to CIDR block for public subnets."
  type        = list(string)
  validation {
    condition     = length(var.public_subnet_cidrs) >= 1
    error_message = "At least one public subnet CIDR must be provided."
  }
}

variable "private_subnet_cidrs" {
  description = "Map of availability zone to CIDR block for private subnets."
  type        = list(string)
  validation {
    condition     = length(var.private_subnet_cidrs) >= 1
    error_message = "At least one private subnet CIDR must be provided."
  }
}

variable "database_subnet_cidrs" {
  description = "Map of availability zone to CIDR block for database subnets."
  type        = list(string)
  default     = []
}

variable "cache_subnet_cidrs" {
  description = "Map of availability zone to CIDR block for cache subnets."
  type        = list(string)
  default     = []
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets (cost-saving for non-prod)."
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "EKS cluster name for Kubernetes discovery tags on subnets."
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}
