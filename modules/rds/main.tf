# customer managed KMS (encrypts storage and secrets)
resource "aws_kms_key" "rds_key" {
    description = "KMS key for RDS ${var.identifier} storage and Secrets Manager"
    deletion_window_in_days = 7    # after this days old keys will be deleted 
    enable_key_rotation = true  
    tags = {
        Name = "${var.vpc_name}-vpc",
        Environment = "${var.env}"
        Terraform = "true"
    }
}

resource "aws_kms_alias" "rds_key_alias" {
    name = "alias/rds/${var.identifier}"
    target_key_id = aws_kms_key.rds_key.key_id
}

# db password 
resource "random_password" "master_password" {
    length = 24
    special = true
    override_special = "!#$%&*()-_=+[]{}<>:?"
}

# secret manager
resource "aws_secretsmanager_secret" "db_credentials" {
    name = "${var.env}/${var.identifier}/credentials"
    description = "Master creds for ${var.identifier} RDS instance"
    kms_key_id = aws_kms_key.rds_key.arn
    recovery_window_in_days = 0         # 0 for instant delete in dev; use 7-30 in enterprise prod

    tags = {
        Name = "${var.vpc_name}-vpc",
        Environment = "${var.env}"
        Terraform = "true"
    }
}

# store credentials for application / external secret operations
resource "aws_secretsmanager_secret_version" "db_credentials" {
    secret_id = aws_secretsmanager_secret.db_credentials.id
    secret_string = jsonencode({
        engine = var.engine
        host = aws_db_instance.this.address
        port = var.port
        database = var.db_name
        username = var.username
        password = random_password.master_password.result
    })
}

# subnets for DB
resource "aws_db_subnet_group" "rds_subnet" {
    subnet_ids = var.subnet_id
    name = "${var.identifier}-subnet-group"
    tags = {
        Name = "${var.vpc_name}-vpc",
        Environment = "${var.env}"
        Terraform = "true"
    }
}

# custom parameter group (enforce SSL/TLS)
resource "aws_db_parameter_group" "secure_postgres" {
    name = "${var.identifier}-secure-pg"
    family = "postgres15"
    description = "Custom parameter group enforcing SSL for ${var.identifier}"

    parameter {
      name = "rds.force_ssl"
      value = "1"       # rejects any unencrypted connections
    }           
    parameter {
      name = "log_connections"
      value = "1"       # auditing requirement
    } 
    parameter {
    name  = "log_disconnections"
    value = "1"
    }
    lifecycle {
        create_before_destroy = true
    }  
    tags = {
        Name = "${var.vpc_name}-vpc",
        Environment = "${var.env}"
        Terraform = "true"
    }
}

# RDS instance
resource "aws_db_instance" "this" {
    identifier = var.identifier

    # engine spec
    engine = "postgres"
    engine_version = var.engine_version
    instance_class = var.instance_class

    # storage & encryption
    allocated_storage = var.allocated_storage
    max_allocated_storage = var.max_allocated_storage
    storage_type = "gp3"
    storage_encrypted = true
    kms_key_id = aws_kms_key.rds_key.arn

    # db creds
    db_name = var.db_name
    username = var.username
    password = random_password.master_password.result
    port = var.port

    # High availability and networking
    multi_az = var.multi_az
    db_subnet_group_name = aws_db_subnet_group.rds_subnet.name
    vpc_security_group_ids = var.security_groups
    publicly_accessible = false

    # custom parameters
    parameter_group_name = aws_db_parameter_group.secure_postgres.name

    # backup and maintainance
    backup_retention_period = var.backup_retention_period
    backup_window = "03:00-04:00"       # UTC off period
    maintenance_window = "Sun:04:30-Sun:05:30"
    copy_tags_to_snapshot = true
    auto_minor_version_upgrade = true

    # deletion guardrails
    deletion_protection = var.deletion_protection
    skip_final_snapshot = var.skip_final_snapshot
    final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.identifier}-final-snapshot"

    # performance & monitoring (free tier disabled)
    # performance_insights_enabled          = true   # (Requires >= db.t3.medium or Graviton)
    # performance_insights_retention_period = 7      # 7 days free tier for PI if enabled
    # enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"] # For MySQL: ["error", "slowquery"]

    tags = {
        Name = "${var.vpc_name}-vpc",
        Environment = "${var.env}"
        Terraform = "true"
    }

    lifecycle {
      ignore_changes = [ 
        password, # Prevents Terraform from overwriting password if rotated later
        latest_restorable_time
       ]
    }
}
