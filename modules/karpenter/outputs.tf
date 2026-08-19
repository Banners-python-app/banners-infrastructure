output "karp_node_arn" {
    description = "Karp node ARN"
    value = aws_iam_role.karpenter_node.arn
}

output "karp_node_name" {
    description = "Karp node name"
    value = aws_iam_role.karpenter_node.name
}