# =============================================================================
# S3 BUCKET — Static Assets
# =============================================================================
# Stores static assets (CSS, JS, images) for the web app. EC2 instances
# reference these via S3 URLs or your app serves them from S3. The bucket
# is private; access is via IAM (EC2 role) or you can add a CloudFront
# distribution and/or public read later.
# =============================================================================

resource "aws_s3_bucket" "static_assets" {
  bucket = "${var.project_name}-static-assets-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.project_name}-static-assets"
  }
}

# Optional: block public access (recommended for private assets)
resource "aws_s3_bucket_public_access_block" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning for static assets (rollback, accidental overwrite protection)
resource "aws_s3_bucket_versioning" "static_assets" {
  count = var.s3_enable_versioning ? 1 : 0

  bucket = aws_s3_bucket.static_assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

# -----------------------------------------------------------------------------
# Data Source: Caller Identity
# -----------------------------------------------------------------------------
# Used to get the current AWS account ID. We use it in the bucket name to
# ensure globally unique S3 bucket names (S3 bucket names are global).
# =============================================================================

data "aws_caller_identity" "current" {}
