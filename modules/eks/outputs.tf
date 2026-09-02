output "cluster_name" {
    description = "The name of the cluster"
    value = aws_eks_cluster.ban_eks_cluster.name
}

output "cluster_endpoint" {
    description = "Endpoint for K8 API server"
    value = aws_eks_cluster.ban_eks_cluster.endpoint
}

output "cluster_certificate_authority_data" {
    description = "Base64 encoded certificate data required to communicate with the cluster"
    value = aws_eks_cluster.ban_eks_cluster.certificate_authority[0].data
}

output "cluster_id" {
    description = "This is cluster ID"
    value = aws_eks_cluster.ban_eks_cluster.id
}

output "cluster_oidc_url" {
    description = "OIDC url"
    value = aws_eks_cluster.ban_eks_cluster.identity[0].oidc[0].issuer
}