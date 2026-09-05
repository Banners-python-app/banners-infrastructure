variable "function_name" {
    type = string
    description = "Func name"
}

variable "retention_in_days" {
    type = number
    description = "Ret days"
    default = 5
}

variable "env" {
    type = string
    description = "Env"
}

variable "handler" {
    type = string
    description = "Main handler"
}

variable "runtime" {
    type = string
    description = "Runtime"
}

variable "timeout" {
    type = number
    description = "Timeout for func"
    default = 30
}

variable "memory_size" {
    type = number
    description = "Mem size"
    default = 512
}

variable "filename" {
    type = string
    description = "Code filename"
}

variable "tracing_mode" {
    type = string
    description = "Whether to sample and trace requests with AWS X-Ray"
    default     = "PassThrough"
}

variable "environment_vars" {
    type = map(string)
    description = "Env vars list"
    default = {}
}

# this is for custom other policies like s3, etc
variable "custom_policy_arns" {
    type = list(strict)
    description = "List of custom policy ARNs to attach to the Lambda execution role"
    default = []
}