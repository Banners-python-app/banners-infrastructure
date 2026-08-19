# 1. Fetch current AWS account ID dynamically
data "aws_caller_identity" "current" {}

# 2. The Strict KMS Key Policy
data "aws_iam_policy_document" "kms" {
  
  # Requirement 1: Allow IAM policies to grant access to the key
  statement {
    sid       = "EnableIAMUserPermissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  # Requirement 2: Key Administrators (Can manage, but CANNOT decrypt)
  statement {
    sid       = "AllowKeyAdministration"
    effect    = "Allow"
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = var.key_administrators
    }
  }

  # Requirement 3: Key Users (Can encrypt/decrypt, but CANNOT manage)
  statement {
    sid       = "AllowKeyUsage"
    effect    = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      # Fallback to the root account if no specific users are provided
      identifiers = length(var.key_users) > 0 ? var.key_users : ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  # Requirement 4: Allow AWS Services (RDS, EBS, Secrets Manager) to use the key on your behalf
  statement {
    sid       = "AllowAWSServicesAttachment"
    effect    = "Allow"
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = length(var.key_users) > 0 ? var.key_users : ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}

# 3. Create the KMS Key
resource "aws_kms_key" "this" {
  description             = var.description
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
  policy                  = data.aws_iam_policy_document.kms.json

  tags = merge(
    {
      Name        = replace(var.alias_name, "alias/", "")
      env = var.env
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

# 4. Create the Key Alias
# Applications should ALWAYS reference the Alias, never the raw Key ARN
resource "aws_kms_alias" "this" {
  name          = var.alias_name
  target_key_id = aws_kms_key.this.key_id
}