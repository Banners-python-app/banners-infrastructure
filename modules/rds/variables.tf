variable "vpc_name" {
    type = string
    description = "VPC name"
}

variable "env" {
    type = string
    description = "Env"
}

variable "subnet_id" {
    type = list(string)
    description = "Subnet IDs"
}

variable "identifier" {
    type = string
    description = "Identifier for KMS"
}

variable "engine" {
    type = string
    description = "DB engine"
    default = "postgres"
}

variable "engine_version" {
    type = string
    description = "Enginer version"
}

variable "db_name" {
    type = string
    description = "DB name"
    default = "bannerdb"
    sensitive = true
}

variable "username" {
    type = string
    description = "Username"
    default = "banneruser"
    sensitive = true
}

variable "port" {
    type = number
    description = "Port"
    default = 5432
}

variable "instance_class" {
    type = string
    description = "Instance type"
    default = "db.t4g.micro"
}

variable "allocated_storage" {
    type = number
    description = "Storage for DB"
    default = 20
}

variable "max_allocated_storage" {
    type = number
    description = "Max storage for DB"
    default = 20
}

variable "security_groups" {
    type = list(string)
    description = "SG"
}

variable "multi_az" {
    type = bool
    description = "used if multi AZ"
    default = false
}

variable "backup_retention_period" {
    type = number
    description = "Days to retain daily backups"
    default = 1
}

variable "deletion_protection" {
    type = bool
    description = "Prevents db from accidental deletion"
    default = false
}

variable "skip_final_snapshot" {
    type = bool
    description = "Skip taking a final snapshot before deleting RDS"
    default = false
}

variable "vpc_id" {
    type = string
    description = "VPC ID"
}