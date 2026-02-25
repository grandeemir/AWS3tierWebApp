# Terraform: Secure 3-Tier AWS Web App

This Terraform stack deploys:

- VPC with 2 public, 2 private app, and 2 private DB subnets across 2 AZs
- Internet Gateway, NAT Gateway, route tables, and associations
- ALB in public subnets
- App tier EC2 Auto Scaling Group in private app subnets
- RDS Multi-AZ instance in private DB subnets
- Security groups between ALB -> App -> DB
- VPC Flow Logs to CloudWatch Logs
- CloudTrail to encrypted/versioned S3 bucket
- GuardDuty detector
- CloudWatch alarms + SNS notifications
- Optional WAFv2 on ALB
- Optional Route53 alias record to ALB

## Prerequisites

- Terraform `>= 1.5`
- AWS credentials configured (`aws configure` or env vars)

## Deploy

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars and set db_password
terraform init
terraform plan
terraform apply
```

## Notes

- By default, this uses a **single NAT Gateway** (cost-optimized, not fully AZ-redundant).
- For production, set `skip_final_snapshot = false` for RDS and tighten `alb_ingress_cidrs`.
- To enable HTTPS on ALB, set `enable_https = true` and provide `acm_certificate_arn`.
