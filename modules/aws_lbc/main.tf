# down official IAM policy for load balancer
#data "http" "name" {
#    url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json"
#}

# create the policy
resource "aws_iam_policy" "alb_policy" {
    name = "${var.cluster_name}-AWSLoadBalancerControllerIAMPolicy"
    policy = file("${path.module}/iam_policy.json")
    description = "Permissions for the AWS Load Balancer Controller"
}

# creating trust policy
data "aws_iam_policy_document" "lbc_trust" {
    statement {
      effect = "Allow"
      actions = [ "sts:AssumeRole", "sts:TagSession" ]

      principals {
        type = "Service"
        identifiers = [ "pods.eks.amazonaws.com" ]
      }
    }
}

# create the role and attach the policy
resource "aws_iam_role" "lbc" {
    assume_role_policy = data.aws_iam_policy_document.lbc_trust.json
    name = "${var.cluster_name}-aws-lbc-role"

    tags = {
      Name = "${var.env}-cluster-role"
      Environment = var.env
      Terraform   = "true"
    }
}

resource "aws_iam_role_policy_attachment" "lbc_attach" {
    policy_arn = aws_iam_policy.alb_policy.arn
    role = aws_iam_role.lbc.name
}

# bind pod identity k8 SA
resource "aws_eks_pod_identity_association" "lbc" {
    cluster_name = var.cluster_name
    namespace = "kube-system"
    service_account = "aws-load-balancer-controller"
    role_arn = aws_iam_role.lbc.arn
}

# helm release
resource "helm_release" "lbc" {
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  namespace        = "kube-system"
  version          = "1.7.2"

  # wait = true ensures Terraform doesn't proceed until the controller is fully operational
  wait             = true 

  values = [
    <<-EOT
    clusterName: "${var.cluster_name}"
    vpcId: "${var.vpc_id}"
    
    # Optional but recommended: Explicitly set region to avoid metadata throttling
    region: "us-east-1" 

    serviceAccount:
      create: true
      name: "aws-load-balancer-controller"
      # If using legacy IRSA instead of EKS Pod Identity, you would add the annotation here:
      # annotations:
      #   eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/aws-load-balancer-controller"

    # ==========================================
    # 1. High Availability (HA) & Resiliency
    # ==========================================
    # Enterprise standard: Run 2 replicas to survive node failures.
    replicaCount: 2

    # Protects the controller from being evicted when cluster memory is full
    priorityClassName: "system-cluster-critical"

    # Pod Disruption Budget guarantees at least 1 controller is ALWAYS running during upgrades
    podDisruptionBudget:
      maxUnavailable: 1

    # Anti-Affinity forces the 2 replicas onto entirely different physical AWS nodes
    affinity:
      podAntiAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchExpressions:
              - key: app.kubernetes.io/name
                operator: In
                values:
                - aws-load-balancer-controller
            topologyKey: kubernetes.io/hostname

    # Enterprise Safety: Never let the LBC run on Spot instances. Pin it to On-Demand nodes.
    #nodeSelector:
     # "karpenter.sh/capacity-type": "on-demand"

    # ==========================================
    # 2. Resource Limits (OOM Protection)
    # ==========================================
    # LBC is written in Go and is very lightweight, but it MUST be capped
    # so a memory leak doesn't crash your worker nodes.
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 200m
        memory: 512Mi

    # ==========================================
    # 3. AWS Security & Compliance (Enterprise)
    # ==========================================
    # Automatically tag every ALB, NLB, and Target Group the controller creates.
    # This is critical for enterprise cost-tracking and SOC2 compliance.
    defaultTags:
      Environment: "${var.env}"
      ManagedBy: "aws-load-balancer-controller"
      Project: "Banner-python"

    # ==========================================
    # 4. Enterprise Settings (Commented Out for Free Tier)
    # ==========================================
    # In enterprise clusters (500+ nodes), we disable strict security group checking 
    # to speed up load balancer creation and prevent AWS API rate limiting.
    # enableServiceMutatorWebhook: false
    # disableSecurityGroupRollback: true

    # AWS WAF integration (Costs extra money, do not enable on Free Tier)
    # enableWaf: false
    # enableWafv2: false
    # enableShield: false
    EOT
  ]

  depends_on = [ aws_eks_pod_identity_association.lbc ]
}