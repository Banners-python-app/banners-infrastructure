# this eso permissions will be used in root so eso has proper permissions
# here we not using IRSA n OIDC bcaz we are using pod identity

# 1. Policy allowing ESO to read Secrets Manager & Decrypt KMS
data "aws_iam_policy_document" "eso_permissions" {
  statement {
    sid     = "AllowSecretsManagerRead"
    effect  = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    # Scoped to your project's secret path
    resources = var.target_secret_arns
  }

  statement {
    sid     = "AllowKMSDecrypt"
    effect  = "Allow"
    actions = ["kms:Decrypt"]
    resources = var.kms_key_arn
  }
}

resource "aws_iam_policy" "eso" {
  name        = "${var.env}-eso-secrets-reader"
  description = "Allows External Secrets Operator to read AWS Secrets Manager"
  policy      = data.aws_iam_policy_document.eso_permissions.json
}

# 2. IAM Role for ESO Controller
resource "aws_iam_role" "eso" {
  name = "${var.env}-external-secrets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eso" {
  role       = aws_iam_role.eso.name
  policy_arn = aws_iam_policy.eso.arn
}

# 3. Bind to the Kubernetes ServiceAccount via EKS Pod Identity
resource "aws_eks_pod_identity_association" "eso" {
  cluster_name    = var.cluster_name
  namespace       = "external-secrets"
  service_account = "external-secrets-sa"
  role_arn        = aws_iam_role.eso.arn
}