variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs where the Load Balancer will be built"
  type        = list(string)
}