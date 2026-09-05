# first generating trust policy using data block
data "aws_iam_policy_document" "trust_policy" {
    # for AWS services
    dynamic "statement" {
        # render this block if user provides service principals
        for_each = length(var.trusted_service_principals) > 0 ? [1] : []
        content {
          effect = "Allow"
        actions = ["sts:AssumeRole"]

        principals {
          type = "Service"
          identifiers = var.trusted_service_principals
            }
        }
    }

    # IRSA for EKS (Federated OIDC)
    dynamic "statement" {
        # render this if OIDC config map if empty ignore
        for_each = var.oicd_config

        content {
            effect  = "Allow"
            actions = ["sts:AssumeRoleWithWebIdentity"]
      
        principals {
            type        = "Federated"
            identifiers = [statement.value.provider_arn]
            }
        
        condition {
            test     = "StringEquals"
            variable = "${statement.value.provider_url}:sub"
            values   = ["system:serviceaccount:${statement.value.namespace}:${statement.value.service_account}"]
            }
        }
    }
}

# the core IAM role
resource "aws_iam_role" "myrole" {
    assume_role_policy = data.aws_iam_policy_document.trust_policy.json
    name = "${var.env}-${var.role_name}"
    permissions_boundary = var.permissions_boundary_arn

    tags = {
      Name = "${var.env}-${var.role_name}"
      env = var.env
      Terraform   = "true"
    }
}

#dynamic policy attachment
# We use a for_each loop to attach as many policies as the user passes in.
# We convert the list to a set() because for_each requires a map or a set.
resource "aws_iam_role_policy_attachment" "custom_attachments" {
    for_each = var.custom_policy_arns
    role = aws_iam_role.myrole.name
    policy_arn = each.value
}