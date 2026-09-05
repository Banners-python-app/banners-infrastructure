# Every function gets a dedicated role , pemissions are explicitly mapped

# creating trust policy 
data "aws_iam_policy_document" "lambda_assume_role" {
    statement {
      actions = [ "sts:AssumeRole" ]
      #effect = "Allow"
      principals {
        type = "Service"
        identifiers = [ "lambda.amazonaws.com" ]
      }
    }
}

# creating a role
resource "aws_iam_role" "this" {
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
    name = "${var.function_name}-execution-role"
}

# allow cloudwatch logging so func can report errors
data "aws_iam_policy_document" "logs" {
    statement {
      effect = "Allow"
      actions = [ 
        "logs:CreateLogStream",
        "logs:PutLogEvents" ]
      resources = [ "${aws_cloudwatch_log_group.this.arn}:*" ]
    }
}

# creates an inline policy and embeds it directly into a specific IAM role
resource "aws_iam_role_policy" "logs" {
    role = aws_iam_role.role.id
    policy = data.aws_iam_policy_document.logs.json
    name = "lambda-cloudwatch-policy"
}

# this used for attaching custom resource policies
resource "aws_iam_role_policy_attachment" "custom_policies" {
    # toset() ensures Terraform treats the list as a unique set, preventing errors if the list order changes
    for_each = toset(var.custom_policy_arns)
    role = aws_iam_role.this.name
    policy_arn = each.value
}

#--------------------------
# This is how we can call custom policies in main workspace like below
# 1. Define the specific permissions for THIS function
/*
data "aws_iam_policy_document" "s3_read" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::my-company-incoming-invoices/*"]
  }
}

# 2. Create the policy resource
resource "aws_iam_policy" "s3_read" {
  name   = "s3-read-for-billing-ocr"
  policy = data.aws_iam_policy_document.s3_read.json
}

# 3. Call your standard module and inject the permissions
module "billing_processor_lambda" {
  source = "./modules/lambda"

  function_name = "billing-ocr-processor"
  runtime       = "python3.13"
  handler       = "main.handler"
  filename      = "function.zip"
  
  # INJECTING THE PERMISSIONS HERE
  custom_policy_arns = [
    aws_iam_policy.s3_read.arn
  ]
}
*/
