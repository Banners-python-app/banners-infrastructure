variable "vpc_cidr" {
    type = string
    description = "VPC CIDR"
    default = "192.168.0.0/16"
}

variable "vpc_name" {
    type = string
    description = "VPC name"
}

variable "env" {
    type = string
    description = "Environment"
}

variable "cidr_pub1" {
    type = string
    description = "Pub subnet cidr"
}

variable "cidr_pub2" {
    type = string
    description = "Pub subnet cidr"
}

variable "cidr_pvt1" {
    type = string
    description = "Pvt subnet cidr"
}

variable "cidr_pvt2" {
    type = string
    description = "Pvt subnet cide"
}

variable "cluster_name" {
    type = string
    description = "This is EKS cluster name"
}

variable "node_groups" {
    type = map(object({
        instance_types = list(string)
        desired_size   = number
        min_size       = number
        max_size       = number
    }))
}

variable "node_group_role_name" {
    type = string
    description = "Node grp name"
}

variable "ecr_policy_name" {
    type = string
    description = "ECR policy name"
}

variable "description" {
    type = string
    description = "This is for KMS for EBS volumes"
}

variable "alias_name" {
    type = string
    description = "This is KMS alias name"
}

variable "engine" {
    type = string
    description = "Engine"
}

variable "engine_version" {
    type = string
    description = "Enginer version"
}

variable "identifier" {
    type = string
    description = "RDS name"
}

variable "repository_name" {
    type = string
    description = "ECR repo name"
}

