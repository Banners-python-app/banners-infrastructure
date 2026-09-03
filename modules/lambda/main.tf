# Lambda function required strict IAM boundary permissions, enforces log retention policies to prevent infinite 
# cloudwatch logs storage costs

resource "aws_cloudwatch_log_group" "this" {
    # checkov:skip=CKV_AWS_338: "Ensure CloudWatch log groups retains logs for at least 1 year"2
    # checkov:skip= CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS"
    name = "/aws/lambda/${var.function_name}"
    retention_in_days = var.retention_in_days
    tags = {
        Name = "${var.function_name}",
        Environment = "${var.env}"
        Terraform = "true"
    }
}

resource "aws_lambda_function" "this" {
    # checkov:skip=CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS"
    # checkov:skip=CKV_AWS_338: "Ensure CloudWatch log groups retains logs for at least 1 year"
    # checkov:skip=CKV_AWS_272: Code signing is not required for this environment tier. CI/CD pipeline enforces artifact integrity
    # checkov:skip=CKV_AWS_117:  "Ensure that AWS Lambda function is configured inside a VPC"
    # checkov:skip=CKV_AWS_115: "Ensure that AWS Lambda function is configured for function-level concurrent execution limit"
    # checkov:skip=CKV_AWS_173: "Check encryption settings for Lambda environmental variable"
    # checkov:skip= CKV_AWS_116: "Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)"

    function_name = var.function_name
    role = aws_iam_role.this.arn
    handler = var.handler       # this is function runs when triggered
    runtime = var.runtime
    timeout = var.timeout
    memory_size = var.memory_size

    # Code file (assumes CI/CD pipeline zips the code)
    filename = var.filename
    source_code_hash = filebase64sha256(var.filename)      # used if filename is same as earlier then based on change fingerprint lambda will take this file

    # tracing (x-ray) for complex microservice 
    tracing_config {
      mode = var.tracing_mode       # Active(used when your triggered cannot generate any logs/traces, eg s3, eventbridge) or PassThrough(used when ur trigger generate traces,eg API GW/ALB)
    }

    # passing env vars
    dynamic "environment" {
        for_each = length(var.environment_vars) > 0 ? [1] : []      # if user passes vars then 1:true otherwise [0]false, completely remove env vars
        content {
          variables = var.environment_vars
        }
    }

    depends_on = [ aws_cloudwatch_log_group.this ]
}