variable "bucket_name" {
  description = "The globally unique name of the S3 bucket"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "force_destroy" {
  description = "Whether to allow bucket deletion even if it contains objects (false for prod)"
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable versioning for object rollback and recovery"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS Key ARN for SSE-KMS encryption. If null, AES256 (SSE-S3) will be used"
  type        = string
  default     = null
}

variable "enable_lifecycle_rules" {
  description = "Enable automated lifecycle management for cost control"
  type        = bool
  default     = true
}

variable "noncurrent_version_expiration_days" {
  description = "Days after which old object versions are permanently deleted"
  type        = number
  default     = 90
}

variable "abort_incomplete_multipart_days" {
  description = "Days after which failed/abandoned multipart uploads are cleaned up"
  type        = number
  default     = 7
}

variable "noncurrent_days_transition" {
    description = "Days after which older versions move to GLACIER"
    type = number
    default = 7
}

variable "noncurrent_days_expiration" {
    description = "Days after GLACIER versions will be deleted"
    type = number
    default = 14
}

variable "log_bucket_target" {
  description = "Target S3 bucket name for server access logging (null to disable)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_name" {
    description = "VPC name"
    type = string
}

variable "env" {
    description = "ENV"
    type = string
}