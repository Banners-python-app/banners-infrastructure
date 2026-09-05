output "pub_subnet_1" {
    description = "Subnet ID of pub 1"
    value = module.vpc.ban_subnet_pub1
}

output "pub_subnet_2" {
    description = "Subnet ID of pub 2"
    value = module.vpc.ban_subnet_pub2
}

output "pvt_subnet_1" {
    description = "Pvt subnet 1"
    value = module.vpc.ban_subnet_pvt1
}

output "pvt_subnet_2" {
    description = "Pvt subnet 2"
    value = module.vpc.ban_subnet_pvt2
}

output "eip" {
    description = "EIP"
    value = module.vpc.ban_eip
}

output "vpc_id" {
    description = "VPC ID"
    value = module.vpc.vpc_id
}

output "vpc_cidr" {
    description = "VPC cidr"
    value = module.vpc.vpc_cidr
}

output "sg_public_id" {
    description = "SG of public ID"
    value = module.sg.sg_public
}

output "sg_pvt_id" {
    description = "SG of pvt ID"
    value = module.sg.sg_private
}

output "sg_db_id" {
    description = "SG DB id"
    value = module.sg.sg_database
}

output "kms_key_arn_ebs" {
    description = "ARN of the key"
    value = module.ebs_kms.key_arn
}

output "ebs_key_id" {
    description = "EBS key id"
    value = module.ebs_kms.key_id
}

output "ebs_alias_arn" {
    description = "ARN of key alias"
    value = module.ebs_kms.alias_arn
}

output "ebs_alias_name" {
    description = "name of key alias"
    value = module.ebs_kms.alias_name
}

output "cluster_name" {
    description = "Cluster name"
    value = module.eks.cluster_name
}

output "cluster_id" {
    description = "Cluster ID"
    value = module.eks.cluster_id
}

output "cluster_endpoint" {
    description = "Cluster endpoint"
    value = module.eks.cluster_endpoint
}

output "cluster_oidc_url" {
    description = "OIDC url cluster"
    value = module.eks.cluster_oidc_url
}

output "karp_node_arn" {
    description = "Karp node ARN"
    value = module.karpenter.karp_node_arn
}

output "karp_node_name" {
    description = "Karp node name"
    value = module.karpenter.karp_node_name
}

output "rds_endpoint" {
    description = "RDS endpoint"
    value = module.rds.endpoint
}

output "rds_address" {
    description = "RDS address"
    value = module.rds.address
}

output "db_name" {
    description = "DB name"
    value = module.rds.db_name
    sensitive = true
}

output "secret_manager_arn" {
    description = "Secret manager ARN"
    value = module.rds.secret_arn
}

output "secret_name" {
    description = "Secret name"
    value = module.rds.secret_name
}

output "rds_kms_key" {
    description = "RDS kms key ARN"
    value = module.rds.kms_key_arn
}

output "ecr_repository_url" {
    description = "ECR repo URL"
    value = module.ecr.repository_rul
}

output "repository_arn" {
    description = "Repo URL"
    value = module.ecr.repository_arn
}

output "eso_role_arn" {
    description = "ESO role arn"
    value = module.eso_iam.role_arn
}

output "eso_role_name" {
    description = "ESO role ARN"
    value = module.eso_iam.role_name
}
