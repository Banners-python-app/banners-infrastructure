variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "The deployment environment"
  type        = string
  default     = "dev"
}