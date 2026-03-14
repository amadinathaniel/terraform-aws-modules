variable "instance_name" {
  description = "Name used for the launch template, ASG, and related resources."
  type        = string
  validation {
    condition     = length(var.instance_name) > 0
    error_message = "instance_name must not be empty."
  }
}

variable "ami_id" {
  description = "Specific AMI ID for the launch template. overrides os_type if provided."
  type        = string
  default     = ""
}

variable "os_type" {
  description = "Operating system type for the launch template (e.g. amazon_linux_2023, ubuntu_2204). Ignored if ami_id is provided."
  type        = string
  default     = "amazon_linux_2023"

  validation {
    condition     = contains(["amazon_linux_2023", "ubuntu"], var.os_type)
    error_message = "os_type must be amazon_linux_2023 or ubuntu."
  }
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the Auto Scaling Group."
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for the security group."
  type        = string
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address in the launch template network interface."
  type        = bool
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB."
  type        = number
  validation {
    condition     = var.root_volume_size >= 8
    error_message = "root_volume_size must be at least 8 GB."
  }
}

variable "root_volume_type" {
  description = "Type of the root EBS volume."
  type        = string
  default     = "gp3"
  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.root_volume_type)
    error_message = "root_volume_type must be one of: gp2, gp3, io1, io2."
  }
}

variable "user_data" {
  description = "User data script for the launch template (will be base64-encoded automatically)."
  type        = string
  default     = null
}

variable "key_name" {
  description = "SSH key pair name for the instances."
  type        = string
  default     = null
}

# ------------------------------------------------------------------------------
# IAM
# ------------------------------------------------------------------------------
variable "iam_role_enabled" {
  description = "Whether to create an IAM role and instance profile."
  type        = bool
  default     = true
}

variable "ssm_managed" {
  description = "Whether to attach the SSM managed policy to the IAM role."
  type        = bool
  default     = true
}

# ------------------------------------------------------------------------------
# Auto Scaling Group
# ------------------------------------------------------------------------------
variable "use_asg" {
  description = "Whether to create an ASG or a standalone instance."
  type        = bool
  default     = true
}

variable "desired_capacity" {
  description = "Desired number of instances in the ASG."
  type        = number
  default     = 1
}

variable "min_size" {
  description = "Minimum number of instances in the ASG."
  type        = number
  validation {
    condition     = var.min_size >= 0
    error_message = "min_size must be 0 or greater."
  }
}

variable "max_size" {
  description = "Maximum number of instances in the ASG."
  type        = number
  validation {
    condition     = var.max_size >= 1
    error_message = "max_size must be at least 1."
  }
}

variable "health_check_type" {
  description = "Health check type for the ASG (EC2 or ELB)."
  type        = string
  default     = "EC2"
  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "health_check_type must be either EC2 or ELB."
  }
}

variable "health_check_grace_period" {
  description = "Seconds after instance launch before health checks start."
  type        = number
  default     = 300
}

variable "target_group_arns" {
  description = "List of ALB target group ARNs to attach to the ASG."
  type        = list(string)
  default     = []
}

# ------------------------------------------------------------------------------
# Elastic IP (single-instance use cases)
# ------------------------------------------------------------------------------
variable "allocate_eip" {
  description = "Whether to allocate an Elastic IP (only meaningful when desired_capacity = 1)."
  type        = bool
  default     = false
}

# ------------------------------------------------------------------------------
# Security
# ------------------------------------------------------------------------------
variable "additional_security_group_ids" {
  description = "List of additional security group IDs to attach to instances."
  type        = list(string)
  default     = []
}

variable "ingress_rules" {
  description = "Map of ingress rules to create on the instance security group."
  type = map(object({
    from_port                    = number
    to_port                      = number
    ip_protocol                  = string
    cidr_ipv4                    = optional(string, null)
    referenced_security_group_id = optional(string, null)
    description                  = optional(string, "")
  }))
  default = {}
}

# ------------------------------------------------------------------------------
# Tags
# ------------------------------------------------------------------------------
variable "common_tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}
