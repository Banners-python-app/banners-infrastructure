output "endpoint" {
  description = "The connection endpoint in host:port format"
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "The hostname / DNS of the database"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "The database port"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "The default database name"
  value       = aws_db_instance.this.db_name
}

output "secret_arn" {
  description = "The ARN of the secret in AWS Secrets Manager containing credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "secret_name" {
  description = "The name of the secret in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.db_credentials.name
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used for RDS and Secrets Manager encryption"
  value       = aws_kms_key.rds_key.arn
}