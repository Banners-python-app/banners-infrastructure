vpc_name = "ban-vpc"
env = "production"
cidr_pub1 = "192.168.1.0/24"
cidr_pub2 = "192.168.2.0/24"
cidr_pvt1 = "192.168.3.0/24"
cidr_pvt2 = "192.168.4.0/24"
cluster_name = "ban-cluster"
node_groups = {
    # node group 1
    "node-1" = {
    instance_types = ["t3.small", "c7i-flex.large"]
    desired_size   = 3
    min_size       = 1
    max_size       = 4
  }
}
node_group_role_name = "ban-eks-node-role"
ecr_policy_name = "ban-ecr-policy"
alias_name = "alias/ebs-csi-key"
description = "This is for KMS for EBS volumes"
engine = "postgres"
engine_version = "18.3"
identifier = "ban-rds"
repository_name = "ban-ecr"