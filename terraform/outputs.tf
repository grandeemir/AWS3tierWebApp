output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "app_subnet_ids" {
  description = "Application subnet IDs"
  value       = aws_subnet.app[*].id
}

output "db_subnet_ids" {
  description = "Database subnet IDs"
  value       = aws_subnet.db[*].id
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.app.dns_name
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.app.name
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "cloudtrail_bucket" {
  description = "CloudTrail S3 bucket"
  value       = aws_s3_bucket.cloudtrail.bucket
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}
