module "vpc" {
    source = "../../modules/vpc"
    vpc_name = var.vpc_name
    vpc_cidr = var.vpc_cidr
    env = var.env
    cidr_pub1 = var.cidr_pub1
    cidr_pub2 = var.cidr_pub2
    cidr_pvt1 = var.cidr_pvt1
    cidr_pvt2 = var.cidr_pvt2
    cluster_name = var.cluster_name
}

module "sg" {
    source = "../../modules/sg"
    ban_vpcid = module.vpc.vpc_id
    env = var.env
    vpc_cidr_block = module.vpc.vpc_cidr
    vpc_name = var.vpc_name
    cluster_name = var.cluster_name
}

module "ebs_kms" {
    source = "../../modules/kms"
    env = var.env
    description = var.description
    alias_name = var.alias_name
    key_administrators = [ "arn:aws:iam::059325865650:user/admin-abhishek" ]        # this is user/role which managing terraform infra
}

module "eks" {
    source = "../../modules/eks"
    vpc_name = var.vpc_name
    cluster_name = var.cluster_name
    env = var.env
    subnet_id = [module.vpc.ban_subnet_pvt1, module.vpc.ban_subnet_pvt2]
    security_grps_pvt_id = [ module.sg.sg_private ]
    node_groups = var.node_groups
    node_group_role_name = var.node_group_role_name
    ecr_policy_name = var.ecr_policy_name
    ebs_kms_key_arn = module.ebs_kms.key_arn

    depends_on = [ module.vpc ]
}

module "karpenter" {
    source = "../../modules/karpenter"
    env = var.env
    cluster_name = var.cluster_name
    cluster_endpoint = module.eks.cluster_endpoint
    depends_on = [ module.eks ]
}

module "rds" {
    source = "../../modules/rds"
    vpc_name = var.vpc_name
    env = var.env
    vpc_id = module.vpc.vpc_id
    security_groups = [ module.sg.sg_database ]
    subnet_id = [ module.vpc.ban_subnet_pvt1, module.vpc.ban_subnet_pvt2 ]
    engine = var.engine
    engine_version = var.engine_version
    identifier = var.identifier         # identifies rds (rds name)
    depends_on = [ module.vpc ]
}

module "aws_lbc" {
    source = "../../modules/aws_lbc"
    cluster_name = var.cluster_name
    vpc_id = module.vpc.vpc_id
    env = var.env
    depends_on = [ module.eks ]
}

module "ecr" {
    source = "../../modules/ecr"
    repository_name = var.repository_name
}

module "argocd" {
    source = "../../modules/argocd"
    cluster_name = var.cluster_name
    depends_on = [ module.eks, module.aws_lbc ]
}

module "eso_iam" {
    source = "../../modules/eso_iam"
    env = var.env
    cluster_name = var.cluster_name
    target_secret_arns = [module.rds.secret_arn]
    kms_key_arn = [module.rds.kms_key_arn]
}

