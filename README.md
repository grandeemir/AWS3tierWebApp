# Secure 3-Tier AWS Web App (Terraform)

![Architecture](../assets/Automated%20Secure%20Multi-tier%20Web%20Application.png)

Production-style Terraform for a secure, automated 3-tier web application on AWS.

## What This Builds

- Networking: VPC, Internet Gateway, 2 public subnets, 2 private app subnets, 2 private DB subnets, route tables, NAT Gateway
- Compute: Application Load Balancer + EC2 Auto Scaling Group in private app subnets
- Data: Multi-AZ Amazon RDS (MySQL or PostgreSQL)
- Security: tiered Security Groups, encryption at rest for RDS and CloudTrail logs, optional WAF
- Observability: VPC Flow Logs, CloudWatch alarms, SNS notifications, CloudTrail, GuardDuty
- DNS (optional): Route53 alias record to ALB

## Architecture Mapping

| Tier | AWS Services | Placement |
|---|---|---|
| Edge/Web | Route53 (optional), ALB, WAF (optional) | Public subnets |
| App | EC2 Launch Template + Auto Scaling Group | Private app subnets |
| Data | RDS Multi-AZ | Private DB subnets |
| Security/Monitoring | Flow Logs, CloudTrail, GuardDuty, CloudWatch, SNS | Account + VPC level |

## Project Structure

```text
terraform/
├── main.tf
├── provider.tf
├── versions.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
└── user_data.sh.tpl
```

## Prerequisites

- Terraform `>= 1.5`
- AWS CLI configured with credentials and region access
- IAM permissions to create VPC, EC2, ELB, RDS, IAM, CloudWatch, SNS, S3, CloudTrail, GuardDuty, WAF, Route53

## Quick Start

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Set at minimum in `terraform.tfvars`:

```hcl
db_password = "ChangeThisStrongPassword123!"
```

Deploy:

```bash
terraform init
terraform plan
terraform apply
```

Destroy when done:

```bash
terraform destroy
```

## Common Configuration

### 1) Enable HTTPS on ALB

```hcl
enable_https        = true
acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxx"
```

### 2) Add Route53 record

```hcl
enable_route53_record = true
route53_zone_id       = "Z1234567890ABC"
route53_record_name   = "app.example.com"
```

### 3) Enable Email Alerts

```hcl
alarm_email = "you@example.com"
```

## Key Outputs

- `alb_dns_name`: public ALB endpoint
- `asg_name`: Auto Scaling Group name
- `rds_endpoint`: database endpoint (sensitive)
- `vpc_id`: VPC identifier
- `cloudtrail_bucket`: S3 bucket storing CloudTrail logs

## Security Notes

- App and DB tiers are private; only ALB is internet-facing.
- Security groups enforce flow: `ALB -> App -> DB`.
- RDS storage encryption is enabled.
- CloudTrail logs are stored in encrypted, versioned, private S3 bucket.
- GuardDuty is enabled for threat detection.

## Cost & Production Guidance

- Current design uses a single NAT Gateway (cost-optimized). For higher resilience, use one NAT Gateway per AZ.
- Set `skip_final_snapshot = false` in production to preserve a final DB snapshot on destroy.
- Restrict `alb_ingress_cidrs` from `0.0.0.0/0` to trusted CIDRs where possible.
- Use stronger instance/database classes for real workloads.

## Troubleshooting

- `terraform: command not found`: install Terraform and ensure it is in `PATH`.
- ALB healthy checks failing: confirm the app port and user data setup (`user_data.sh.tpl`).
- RDS creation issues: verify subnet CIDRs, DB engine/version compatibility, and quotas.

## Next Improvements

- Split into reusable modules (`network`, `compute`, `database`, `security`, `observability`)
- Add remote backend (S3 + DynamoDB lock table)
- Add CI/CD for `terraform fmt`, `validate`, `plan` on pull requests
