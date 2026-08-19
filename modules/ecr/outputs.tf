output "repository_rul" {
    description = "URL of repo"
    value = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
    description = "ARN of repo"
    value = aws_ecr_repository.this.arn
}