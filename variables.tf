# =============================================================================
# INPUT VARIABLES
# =============================================================================
# Variables allow you to parameterize your configuration. They make the code
# reusable across environments (dev/staging/prod) without changing .tf files.
# Use: terraform apply -var="environment=prod" or .tfvars files.
# =============================================================================

# -----------------------------------------------------------------------------
# General
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region where all resources will be created (e.g. us-east-1)."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod) used for tagging and naming."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used as prefix for resource names."
  type        = string
  default     = "ha-web-app"
}

# -----------------------------------------------------------------------------
# Network (VPC)
# -----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC. All subnets will be carved from this range."
  type        = string
  default     = "10.0.0.0/16"
}

# We use a list of AZ names. Terraform will create subnets in each.
# count/for_each will iterate over these.
variable "availability_zones" {
  description = "List of Availability Zones for high availability (minimum 2 for ALB/ASG)."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# -----------------------------------------------------------------------------
# Auto Scaling Group (EC2)
# -----------------------------------------------------------------------------

variable "asg_min_size" {
  description = "Minimum number of EC2 instances in the Auto Scaling Group."
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of EC2 instances in the Auto Scaling Group."
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  description = "Desired (initial) number of EC2 instances."
  type        = number
  default     = 2
}

variable "instance_type" {
  description = "EC2 instance type (e.g. t3.micro for dev, t3.small for prod)."
  type        = string
  default     = "t3.micro"
}

# -----------------------------------------------------------------------------
# S3 (Static Assets)
# -----------------------------------------------------------------------------

variable "s3_enable_versioning" {
  description = "Enable versioning on the S3 bucket for static assets."
  type        = bool
  default     = true
}
