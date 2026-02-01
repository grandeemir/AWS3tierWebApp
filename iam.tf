# =============================================================================
# IAM ROLES
# =============================================================================
# EC2 instances need permission to read from S3 (static assets). Best practice:
# use an IAM *role* attached to the instance, not long‑lived access keys.
# The role is assumed by the EC2 instance via the instance profile.
# =============================================================================

# -----------------------------------------------------------------------------
# IAM Role for EC2
# -----------------------------------------------------------------------------
# This role can be assumed only by EC2 (trust policy). Use it for:
# - S3 read access (static assets)
# - CloudWatch logs (optional)
# - SSM Session Manager (optional, for SSH-less access)
# -----------------------------------------------------------------------------

resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}

# -----------------------------------------------------------------------------
# IAM Policy: S3 Read for Static Assets
# -----------------------------------------------------------------------------
# Grants ListBucket and GetObject on our static-assets bucket. EC2 can
# pull CSS, JS, images from S3 (e.g. via application config or redirects).
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy" "ec2_s3" {
  name = "${var.project_name}-ec2-s3-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.static_assets.arn,
          "${aws_s3_bucket.static_assets.arn}/*"
        ]
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Instance Profile
# -----------------------------------------------------------------------------
# An instance profile is a container for an IAM role. You attach the
# *instance profile* to the EC2 launch template; AWS associates the role
# with the instance so the app can call S3 without access keys.
# =============================================================================

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2.name
}
