# =============================================================================
# OUTPUTS
# =============================================================================
# Outputs expose important values after apply (e.g. ALB URL, bucket name).
# Use: terraform output
# =============================================================================

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer. Use this URL to access the app."
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Route53 zone ID of the ALB (for alias records if you use Route53)."
  value       = aws_lb.main.zone_id
}

output "app_url" {
  description = "URL to access the web app (HTTP)."
  value       = "http://${aws_lb.main.dns_name}"
}

output "s3_bucket_static_assets" {
  description = "Name of the S3 bucket for static assets. Upload CSS, JS, images here."
  value       = aws_s3_bucket.static_assets.id
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (EC2 / ASG)."
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (ALB, NAT)."
  value       = aws_subnet.public[*].id
}
