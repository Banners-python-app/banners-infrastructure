variable "ami" {
    type = string
    description = "AMI type"
}

variable "instance_type" {
    type = string
    description = "Instance type"
}

variable "subnet_id" {
    type = string
    description = "Public subnet"
}

variable "key_name" {
    type = string
    description = "Key name"
    default = "newkp.pem"
}

variable "security_groups" {
    type = list(string)
    description = "SGs"
}

variable "iam_instance_profile" {
    type = string
    description = "Inst profile"
    default = null
}

variable "user_data" {
    type = string
    description = "User data"
    default = ""
}

variable "public_ip" {
    type = bool
    description = "Public Ip for Ec2"
    default = false
}

variable "volume_size" {
    type = number
    description = "Vol size"
    default = 8
}

variable "vpc_name" {
    type = string
    description = "VPC name"
}

variable "env" {
    type = string
    description = "This is ENV"
}