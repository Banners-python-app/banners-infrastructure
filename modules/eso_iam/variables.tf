variable "env" {
    description = "Env"
    type = string
}

variable "target_secret_arns" {
    description = "Target secret manager ARN"
    type = list(string)
}

variable "kms_key_arn" {
    description = "Key ARN"
    type = list(string)
    #default = []
}

variable "cluster_name" {
    description = "CLuster name"
    type = string
}