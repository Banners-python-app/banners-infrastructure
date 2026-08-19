variable "trusted_service_principals" {
    description = "List of AWS services allowed to assume this role (e.g., ['ec2.amazonaws.com', 'ecs-tasks.amazonaws.com'])"
    type = list(string)
    default = []
}

variable "role_name" {
    description = "The name of the IAM role (e.g., app-backend-role)"
    type = string
}

variable "env" {
    description = "Env (e.g., dev, staging, prod)"
    type = string
}

variable "permissions_boundary_arn" {
    description = "ARN of the policy that is used to set the permissions boundary for the role (Enterprise security standard)"
    type = string
    default = null
}

variable "custom_policy_arns" {
    description = "A list of IAM Policy ARNs to attach to this role"
    type = map(string)
    #default = [] 
}