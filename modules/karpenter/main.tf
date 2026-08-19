# Karp node role
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

resource "aws_iam_role" "karpenter_node" {
    assume_role_policy = data.aws_iam_policy_document.node_assume_role.json
    name = "KarpenterNodeRole-${var.cluster_name}"

    tags = {
      Name = "${var.env}-cluster-role"
      env = var.env
      Terraform   = "true"
    }
    depends_on = [ data.aws_iam_policy_document.node_assume_role ]
}

resource "aws_iam_role_policy_attachment" "karpenter_node_policies" {
    for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"])

    policy_arn = each.value
    role = aws_iam_role.karpenter_node.name
    depends_on = [ aws_iam_role.karpenter_node ]
}

# Karp requires an Instance profile to attach to the EC2 it builds
resource "aws_iam_instance_profile" "karpenter_profile" {
    name = "KarpenterNodeInstanceProfile-${var.cluster_name}"
    role = aws_iam_role.karpenter_node.name
}

# Allow EC2 instances to join EKS cluster
resource "aws_eks_access_entry" "karpenter" {
    cluster_name  = var.cluster_name
    principal_arn = aws_iam_role.karpenter_node.arn # Hard dependency ensures the role exists first
    type          = "EC2_LINUX"
}

#Karp controller role (pod identity)
# Our Karp pod is inside the controller nodes and we need to create role and attach to it so it can have all EC2 access
data "aws_iam_policy_document" "karp_controller_assume_role" {
    statement {
      effect = "Allow"
      actions = [ "sts:AssumeRole", "sts:TagSession" ]
      principals {
        type = "Service"
        identifiers = ["pods.eks.amazonaws.com"]
      }
    }
}

resource "aws_iam_role" "karpenter_controller" {
    name = "KarpenterControllerRole-${var.cluster_name}"
    assume_role_policy = data.aws_iam_policy_document.karp_controller_assume_role.json
}

data "aws_iam_policy_document" "karp_controller_policy" {
    statement {
      effect = "Allow"
      actions = [ 
      "ec2:RunInstances",
      "ec2:CreateFleet",
      "ec2:CreateTags",
      "ec2:TerminateInstances",
      "ec2:DescribeLaunchTemplates",
      "ec2:DeleteLaunchTemplate",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeImages",
      "ec2:CreateLaunchTemplate",
      "ssm:GetParameter",
      "pricing:GetProducts",
      "eks:DescribeCluster",
      "iam:CreateInstanceProfile",  
      "iam:GetInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:TagInstanceProfile"
       ]
       resources = [ "*" ]
    }
    statement {
      effect = "Allow"
      actions = ["iam:PassRole", "iam:ListInstanceProfiles"]
      resources = [ aws_iam_role.karpenter_node.arn, aws_iam_instance_profile.karpenter_profile.arn ]
    }
}

resource "aws_iam_policy" "karpenter_controller" {
    name = "karpenterControllerPolicy-${var.cluster_name}"
    policy = data.aws_iam_policy_document.karp_controller_policy.json
}

resource "aws_iam_role_policy_attachment" "karpenter_controller" {
    role = aws_iam_role.karpenter_controller.name
    policy_arn = aws_iam_policy.karpenter_controller.arn
}

# bind IAM role to the K8 serviceaccount using pod identity
resource "aws_eks_pod_identity_association" "karpenter" {
    cluster_name = var.cluster_name
    namespace = "kube-system"
    service_account = "karpenter"
    role_arn = aws_iam_role.karpenter_controller.arn
}

# deploy karpenter crd first
resource "helm_release" "karp_crd" {
    namespace = "kube-system"
    create_namespace = true
    name = "karpenter-crd"
    repository = "oci://public.ecr.aws/karpenter"
    chart = "karpenter-crd"
    version = "1.3.0"
    wait = true     # this will wait until karpenter pods fully ready
}

# Helm installation
resource "helm_release" "karpenter" {
    namespace = "kube-system"
    create_namespace = true
    name = "karpenter"
    repository = "oci://public.ecr.aws/karpenter"
    chart = "karpenter"
    version = "1.3.0"

    values = [ 
        yamlencode({
            replies = 2

            settings = {
                clusterName = var.cluster_name
                clusterEndpoint = var.cluster_endpoint
                # required for spot instances if ur using it. whenever AWS reclaim spot vms then this queue comes in
                # and within 2 mins it recreate new instances wihtout getting old pods gone
                interruptionQueue = ""         
                ignoreVersionMismatch = true
            }
            serviceAccount = {
                create = true
                name = "karpenter"
            }

            controller = {
                resources = {
                    requests = {
                        cpu = "1"
                        memory = "1Gi"
                    }
                    limits = {
                        cpu = "1"
                        memory = "1Gi"
                    }
                }
            }

            # security and stability (this ensures karp pods runs on only eks managed nodes)
            affinity = {
                nodeAffinity = {
                    requiredDuringSchedulingIgnoredDuringExecution = {
                        nodeSelectorTerms = [{
                            matchExpressions = [{
                                key = "karpenter.sh/nodepool"
                                operator = "DoesNotExist"
                            }]
                        }]
                    }
                }
                # Force the 2 replicas to run on entirely different physical AWS servers
                podAntiAffinity = {
                    requiredDuringSchedulingIgnoredDuringExecution = [{
                        topologyKey = "kubernetes.io/hostname"
                    }]
                }
            }
        })
     ]

    wait = true

    depends_on = [ helm_release.karp_crd, aws_eks_pod_identity_association.karpenter, aws_eks_access_entry.karpenter ]
}