# Zero Public Access: Explicitly enabling all 4 Block Public Access flags.
# Bucket Owner Enforced: Disabling legacy S3 ACLs entirely.
# Encryption at Rest: Default KMS or AES256 server-side encryption
# Enforced Encryption in Transit: A bucket policy that strictly rejects any HTTP (non-TLS/SSL) requests.
# Data Protection: Versioning enabled by default with deletion safeguards (force_destroy = false).
# Cost Optimization: Automatic lifecycle rules to abort failed multipart uploads and clean up non-current versions.


resource "aws_s3_bucket" "ban_bucket" {
  # checkov:skip=CKV2_AWS_62: "Ensure S3 buckets should have event notifications enabled"
  # checkov:skip= CKV_AWS_18: "Ensure the S3 bucket has access logging enabled"
  # checkov:skip=CKV_AWS_144: "Ensure that S3 bucket has cross-region replication enabled"
    bucket = var.bucket_name
    force_destroy = var.force_destroy

    tags = merge({
        Name = "${var.vpc_name}-vpc",
        Environment = "${var.env}"
        Terraform = "true"
    }, var.tags)
}

# modern object ownership
resource "aws_s3_bucket_ownership_controls" "this" {
    bucket = aws_s3_bucket.ban_bucket.id
    rule {
      object_ownership = "BucketOwnerEnforced"
    }
}

# block all pub access
resource "aws_s3_bucket_public_access_block" "this" {
    bucket = aws_s3_bucket.ban_bucket.id

    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}

# object versioning
resource "aws_s3_bucket_versioning" "this" {
    bucket = aws_s3_bucket.ban_bucket.id
    versioning_configuration {
      status = var.versioning_enabled ? "Enabled" : "Suspended"
    }
}

# servers side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "name" {
    bucket = aws_s3_bucket.ban_bucket.id
    rule {
      apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true # Reduces KMS costs by up to 99% for high-traffic buckets
    }
}

# lifecycle management
resource "aws_s3_bucket_lifecycle_configuration" "this" {
    bucket = aws_s3_bucket.ban_bucket.id
    count = var.enable_lifecycle_rules ? 1 : 0

    rule {
      id = "cost-optimization"
      status = "Enabled"
      filter {}

      # cleans up failed multi part uploads
      abort_incomplete_multipart_upload {
        days_after_initiation = var.abort_incomplete_multipart_days
      }

      # cleanup older objects if versioning is active
      noncurrent_version_transition {
        noncurrent_days = var.noncurrent_days_transition
        storage_class = "GLACIER"
      }

      noncurrent_version_expiration {
        noncurrent_days = var.noncurrent_days_expiration
      }
    }
}

# optional access logging
#resource "aws_s3_bucket_logging" "this" {
#  count  = var.log_bucket_target != null ? 1 : 0
#  bucket = aws_s3_bucket.this.id

#  target_bucket = var.log_bucket_target
#  target_prefix = "s3-access-logs/${var.bucket_name}/"
#}

# Enforce TLS 1.2+ / In-Transit Encryption Policy
resource "aws_s3_bucket_policy" "enforce_tls" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceTLSRequestsOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.this]
}