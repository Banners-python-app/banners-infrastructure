# cluster iam role
data "aws_iam_policy_document" "cluster_assume_role" {
    statement {
      effect = "Allow"
      actions = [ "sts:AssumeRole" ]
      principals {
        type = "Service"
        identifiers = [ "eks.amazonaws.com" ]
      }
    }
}

resource "aws_iam_role" "cluster_role" {
    assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json
    name = "${var.cluster_name}-cluster-role"
    tags = {
        Name = "${var.vpc_name}-vpc",
        Environment = "${var.env}"
        Terraform = "true"
    }
    depends_on = [ data.aws_iam_policy_document.cluster_assume_role ]
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
    role = aws_iam_role.cluster_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    depends_on = [ aws_iam_role.cluster_role ]
}

# enable KMS key for encrypting EKS secrets
resource "aws_kms_key" "eks" {
    description = "EKS secrets encryption key for ${var.cluster_name}"
    enable_key_rotation = true
    deletion_window_in_days = 7
}

# retention policy for CW logs
resource "aws_cloudwatch_log_group" "eks" {
    name = "/aws/eks/${var.cluster_name}/cluster"
    retention_in_days = 7       # automatically purges old logs after 7 days save money
}

# cluster EKS
resource "aws_eks_cluster" "ban_eks_cluster" {
    name = var.cluster_name
    role_arn = aws_iam_role.cluster_role.arn
    version = var.eks_version
    vpc_config {
        subnet_ids = var.subnet_id
        security_group_ids = var.security_grps_pvt_id
        endpoint_public_access = true
        endpoint_private_access = true
    }

    access_config {
        authentication_mode = "API_AND_CONFIG_MAP"
        bootstrap_cluster_creator_admin_permissions = true
    }

    # enable control plane logging
    enabled_cluster_log_types = ["api","audit","authenticator", "controllerManager", "scheduler"]

    # enabling KMS for secrets encryption
    encryption_config {
      provider {
        key_arn = aws_kms_key.eks.arn
      }
      resources = ["secrets"]
    }

    depends_on = [ aws_iam_role.cluster_role, aws_kms_key.eks ]
}

#------------------------
# node group IAM role

# assume trust role policy 
data "aws_iam_policy_document" "node_assume_role" {
    statement {
      effect = "Allow"
      actions = [ "sts:AssumeRole" ]
      principals {
        type = "Service"
        identifiers = [ "ec2.amazonaws.com" ]
      }
    }
}

# ECR policy document
data "aws_iam_policy_document" "ecr_node_role" {
    statement {
      effect = "Allow"
      actions = [ 
        "sts:GetServiceBearerToken",
        "ecr-public:GetAuthorizationToken",
        "ecr-public:BatchCheckLayerAvailability",
        "ecr-public:GetRepositoryPolicy",
        "ecr-public:DescribeRepositories",
        "ecr-public:DescribeImages",
        "ecr-public:DescribeImageTags",
        "ecr-public:DescribeRegistries",
        "ecr-public:GetRepositoryCatalogData",
        "ecr-public:GetRegistryCatalogData"
       ]
       resources = [ "*" ]
    }
}

resource "aws_iam_policy" "ecr_node_policy" {
    policy = data.aws_iam_policy_document.ecr_node_role.json
    name = var.ecr_policy_name
    tags = {
        Name = "${var.vpc_name}-vpc",
        Environment = "${var.env}"
        Terraform = "true"
    }
    depends_on = [ data.aws_iam_policy_document.ecr_node_role ]
}

# node iam role
resource "aws_iam_role" "node_role" {
    assume_role_policy = data.aws_iam_policy_document.node_assume_role.json
    name = var.node_group_role_name
    tags = {
        Name = "${var.vpc_name}-vpc",
        Environment = "${var.env}"
        Terraform = "true"
    }
    depends_on = [ data.aws_iam_policy_document.node_assume_role, aws_iam_policy.ecr_node_policy ]
}

# attaching ECR policy
resource "aws_iam_role_policy_attachment" "ecr_policy" {
    policy_arn = aws_iam_policy.ecr_node_policy.arn
    role = aws_iam_role.node_role.name
    depends_on = [ aws_iam_role.node_role ]
}

# Standard EKS Worker Node Policies
resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    role = aws_iam_role.node_role.name
    depends_on = [ aws_iam_role.node_role ]
}

# we can also add VPC CNI policy pod level as configured below
resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    role = aws_iam_role.node_role.name
    depends_on = [ aws_iam_role.node_role ]
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    role = aws_iam_role.node_role.name
    depends_on = [ aws_iam_role.node_role ]
}

# managed node groups
resource "aws_eks_node_group" "this_nodes" {
    for_each = var.node_groups
    cluster_name = var.cluster_name
    node_role_arn = aws_iam_role.node_role.arn
    node_group_name = "${var.cluster_name}-${each.key}"
    subnet_ids = var.subnet_id
    ami_type = "AL2023_x86_64_STANDARD"
    instance_types = each.value.instance_types

    scaling_config {
      desired_size = each.value.desired_size
      min_size = each.value.min_size
      max_size = each.value.max_size
    }

    depends_on = [ aws_eks_cluster.ban_eks_cluster, aws_iam_role.node_role ]
}

###########
# S3 mountpoint setup
# trust policy for the pod
data "aws_iam_policy_document" "s3_csi_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
  depends_on = [ aws_eks_cluster.ban_eks_cluster, aws_eks_node_group.this_nodes ]
}

resource "aws_iam_role" "s3_csi_role" {
  name = "${var.cluster_name}-s3-csi-role"
  assume_role_policy = data.aws_iam_policy_document.s3_csi_assume_role.json
  depends_on = [ data.aws_iam_policy_document.s3_csi_assume_role ]
  tags = {
      Name = "${var.env}-s3-csi-role"
      Environment = var.env
      Terraform   = "true"
    }  
}

data "aws_iam_policy_document" "s3_csi_policy" {
  statement {
    effect = "Allow"
    actions = [ "s3:ListBucket",
                "s3:GetObject",
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:DeleteObject" 
              ]
    resources = ["arn:aws:s3:::*", 
                  "arn:aws:s3:::*/*"]

  }
}

resource "aws_iam_policy" "s3_csi_policy" {
  name = "${var.cluster_name}-s3-csi-policy"
  policy = data.aws_iam_policy_document.s3_csi_policy.json
}

resource "aws_iam_role_policy_attachment" "s3_csi_driver_policy" {
  policy_arn = aws_iam_policy.s3_csi_policy.arn
  role = aws_iam_role.s3_csi_role.name
  depends_on = [ aws_iam_role.s3_csi_role ]
}

resource "aws_eks_pod_identity_association" "s3_csi_driver" {
  cluster_name    = aws_eks_cluster.ban_eks_cluster.name
  namespace       = "kube-system"
  service_account = "s3-csi-driver-sa" # The default ServiceAccount for the Mountpoint S3 driver
  role_arn        = aws_iam_role.s3_csi_role.arn
  depends_on = [ aws_iam_role.s3_csi_role ]
}

###########
# EBS CSI setup using old std enterprise way IRSA
# To IRSA to work our cluster act as identity provider to AWS IAM. When we create cluster we get OIDC issuer url
# fetch cluster's TLS certificate
data "tls_certificate" "eks" {
    url = aws_eks_cluster.ban_eks_cluster.identity[0].oidc[0].issuer
}

# create AWS IAM provider 
resource "aws_iam_openid_connect_provider" "eks" {
    client_id_list = ["sts.amazonaws.com"]
    thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
    url = aws_eks_cluster.ban_eks_cluster.identity[0].oidc[0].issuer
}

# IRSA role and KMS key
data "aws_iam_policy_document" "ebs_assume_role" {
    statement {
      effect = "Allow"
      actions = ["sts:AssumeRoleWithWebIdentity"]
      condition {
        test = "StringEquals"
        variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"        # "cluster oidc url":"sts.amazonaws.com"
        values = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]        # tis binds the role to the kube-system:ebs--
      }
      principals {
        identifiers = [aws_iam_openid_connect_provider.eks.arn]
        type = "Federated"
      }
    }
}

resource "aws_iam_role" "ebs_role" {
    assume_role_policy = data.aws_iam_policy_document.ebs_assume_role.json
    name = "${var.cluster_name}-ebs-role"
    tags = {
        Name = "${var.env}-s3-csi-role"
        Environment = var.env
        Terraform   = "true"
    }
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy" {
    role = aws_iam_role.ebs_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# attach custom KMS policy
resource "aws_iam_role_policy" "ebs_csi_kms" {
    name = "KMSAccessForEBS"
    role = aws_iam_role.ebs_role.name

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Action = [
            "kms:CreateGrant",
            "kms:ListGrants",
            "kms:RevokeGrant",
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:GenerateDataKeyWithoutPlaintext",
            "kms:DescribeKey" ]
            # Restrict to your specific KMS Key ARN used for EBS volumes
            Resource = [var.ebs_kms_key_arn]
        }]
    })
}

# EBS driver
resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.ban_eks_cluster.name
  addon_name               = "aws-ebs-csi-driver"
  
  # Inject the IAM Role we just created! AWS automatically annotates the ServiceAccount.
  service_account_role_arn = aws_iam_role.ebs_role.arn
  
  # Resolve conflicts allows Terraform to overwrite any manual changes in the cluster
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi_driver_policy, aws_iam_role.ebs_role 
  ]
}

#sample storageclass using above way
#apiVersion: storage.k8s.io/v1
#kind: StorageClass
#metadata:
#  name: ebs-gp3
#  annotations:
#    storageclass.kubernetes.io/is-default-class: "true"
#provisioner: ebs.csi.aws.com
#reclaimPolicy: Retain              # Prod standard: Retain prevents accidental data loss if PVC is deleted
#allowVolumeExpansion: true         # Allows you to increase disk size without downtime
#volumeBindingMode: WaitForFirstConsumer # ABSOLUTELY CRITICAL FOR MULTI-AZ 
#parameters:
#  type: gp3
#  encrypted: "true"
#  kmsKeyId: arn:aws:kms:us-east-1:123456789012:key/your-kms-key-id

# lets add addons
resource "aws_eks_addon" "addons" {
  for_each = toset(["vpc-cni", "coredns", "kube-proxy", "eks-pod-identity-agent", "aws-mountpoint-s3-csi-driver"])
  cluster_name = aws_eks_cluster.ban_eks_cluster.name
  addon_name = each.value

  # Standard practice: don't overwrite custom configurations if we update the cluster
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [ aws_eks_node_group.this_nodes ]

}

resource "time_sleep" "wait_for_alb_webhook" {
  depends_on = [aws_eks_addon.addons]
  create_duration = "20s"
}

# Grant your personal AWS user Admin Access to the cluster
#resource "aws_eks_access_entry" "local_admin" {
#  cluster_name  = aws_eks_cluster.this_cluster.name
  # Change this to match your actual local IAM user or SSO role!
#  principal_arn = "arn:aws:iam::059325865650:user/admin-abhishek" 
#  type          = "STANDARD"
#}

#resource "aws_eks_access_policy_association" "local_admin_policy" {
#  cluster_name  = aws_eks_cluster.this_cluster.name
#  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#  principal_arn = aws_eks_access_entry.local_admin.principal_arn

#  access_scope {
#    type = "cluster"
#  }
#}