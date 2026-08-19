variable "env" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "alias_name" {
  description = "Display name of the key (must start with alias/)"
  type        = string
}

variable "description" {
  description = "Description of what this KMS key is used for"
  type        = string
}

variable "deletion_window_in_days" {
  description = "Days before the key is permanently deleted (7-30)"
  type        = number
  default     = 7 # Enterprise standard to prevent accidental instant deletion
}

variable "enable_key_rotation" {
  description = "Automatically rotate the underlying KMS key material every 365 days"
  type        = bool
  default     = true # Mandatory for PCI-DSS / SOC2 compliance
}

variable "key_administrators" {
  description = "List of IAM ARNs allowed to administer the key (e.g., CI/CD role)"
  type        = list(string)
}

variable "key_users" {
  description = "List of IAM ARNs allowed to use the key for encrypt/decrypt (e.g., EKS IRSA Roles)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Standard resource tags"
  type        = map(string)
  default     = {}
}