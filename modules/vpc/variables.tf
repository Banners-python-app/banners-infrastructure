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

