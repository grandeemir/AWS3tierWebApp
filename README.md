# Highly Available Web App — Terraform

**Architecture:** User → ALB → EC2 (Auto Scaling) → S3 (static assets)

Terraform project for a highly available web application on AWS, using:

- **VPC** with 2 AZs, public + private subnets, Internet Gateway + NAT Gateways  
- **ALB** in public subnets  
- **Auto Scaling Group** with EC2 in private subnets  
- **S3** bucket for static assets  
- **IAM** roles for EC2 (S3 access)

## Terraform Concepts Used

| Concept | Where |
|--------|--------|
| **count** | Public/private subnets, NAT gateways, EIPs, route table associations |
| **for_each** | Private route tables (per AZ) and their associations |
| **Security groups** | ALB (80/443 from internet), EC2 (80 from ALB only) |
| **Data sources** | AMI lookup (`data.aws_ami`), caller identity (`data.aws_caller_identity`) |
| **user_data** | Launch template: install nginx, create simple index page |

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0  
- AWS CLI configured (credentials + region) or env vars `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`

## Usage

```bash
terraform init
terraform plan
terraform apply
```

After apply, use the ALB DNS name to access the app:

```bash
terraform output app_url
curl $(terraform output -raw app_url)
```

## Outputs

| Output | Description |
|--------|-------------|
| `app_url` | HTTP URL of the web app |
| `alb_dns_name` | ALB DNS name |
| `s3_bucket_static_assets` | S3 bucket for static assets |
| `vpc_id`, `private_subnet_ids`, `public_subnet_ids` | Network IDs |

## Variables

See `variables.tf`. Examples:

- `aws_region` — default `us-east-1`  
- `availability_zones` — default `["us-east-1a", "us-east-1b"]`  
- `asg_min_size`, `asg_max_size`, `asg_desired_capacity`  
- `instance_type` — default `t3.micro`

Override via `-var`, `-var-file`, or `*.auto.tfvars`.

## Cleanup

```bash
terraform destroy
```

## SAA Relevance

This setup touches a large portion of SAA topics: VPC, subnets, IGW/NAT, ALB, ASG, EC2, S3, IAM, security groups, and high availability across AZs.
