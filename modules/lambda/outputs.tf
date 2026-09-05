output "function_name" {
    description = "Func name"
    value = aws_lambda_function.this.function_name
}

output "lambda_role_name" {
    description = "Lambda role"
    value = aws_iam_role.this.name
}

output "lambda_role_arn" {
    description = "Lambda role"
    value = aws_iam_role.this.arn
}