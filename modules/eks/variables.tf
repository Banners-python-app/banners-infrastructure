variable "cluster_name" {
    type = string
    description = "Cluster name"
}

variable "vpc_name" {
    type = string
    description = "VPC name"
}

variable "env" {
    type = string
    description = "ENV"
}

variable "eks_version" {
    type = string
    description = "EKS version"
    default = "1.33"
}

variable "subnet_id" {
    type = list(string)
    description = "Subnet ID"
}

variable "security_grps_pvt_id" {
    type = list(string)
    description = "SG ID"
}

variable "node_group_role_name" {
    type = string
    description = "Node role grp"
}

variable "ecr_policy_name" {
    type = string
    description = "ECR policy name"
}

variable "node_groups" {
    description = "Node grps"
    type = map(object({
        instance_types = list(string)
        desired_size = number
        min_size = number
        max_size = number
    }))
}

variable "ebs_kms_key_arn" {
    description = "KMS arn for ebs"
    type = string
}