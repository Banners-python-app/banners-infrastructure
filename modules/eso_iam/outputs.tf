output "role_arn" {
  description = "The ARN of the IAM Role created for External Secrets Operator"
  value       = aws_iam_role.eso.arn
}

output "role_name" {
  description = "The name of the IAM Role created for External Secrets Operator"
  value       = aws_iam_role.eso.name
}

output "policy_arn" {
  description = "The ARN of the least-privilege IAM policy attached to the role"
  value       = aws_iam_policy.eso.arn
}

output "association_id" {
  description = "The ID of the EKS Pod Identity association"
  value       = aws_eks_pod_identity_association.eso.id
}