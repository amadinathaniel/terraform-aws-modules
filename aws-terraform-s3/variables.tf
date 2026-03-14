variable "bucket_name" {
  description = "Name of the S3 bucket."
  type        = string
  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "bucket_name must be between 3 and 63 characters."
  }
}

variable "force_destroy" {
  description = "Whether to force destroy the bucket and all objects."
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Whether to enable versioning on the bucket."
  type        = bool
  default     = false
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm (aws:kms or AES256)."
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "aws:kms"], var.sse_algorithm)
    error_message = "sse_algorithm must be AES256 or aws:kms."
  }
}

variable "kms_key_id" {
  description = "KMS key ID for server-side encryption (required if sse_algorithm is aws:kms)."
  type        = string
  default     = null
}

variable "lifecycle_rules" {
  description = "List of lifecycle rule configurations for the bucket."
  type = list(object({
    id                                     = string
    enabled                                = optional(bool, true)
    prefix                                 = optional(string, null)
    expiration_days                        = optional(number, null)
    transition_days                        = optional(number, null)
    transition_storage_class               = optional(string, null)
    abort_incomplete_multipart_upload_days = optional(number, null)
  }))
  default = []
}

variable "logging" {
  description = "Access logging configuration."
  type = object({
    target_bucket = string
    target_prefix = string
  })
  default = null
}

variable "tags" {
  description = "Tags applied to the S3 bucket and related resources."
  type        = map(string)
  default     = {}
}
