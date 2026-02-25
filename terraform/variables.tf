variable "project_name" {
  description = "Project identifier used for naming resources."
  type        = string
  default     = "secure-3tier"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Two public subnet CIDRs (one per AZ)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "public_subnet_cidrs must contain exactly 2 CIDR blocks."
  }
}

variable "app_subnet_cidrs" {
  description = "Two private application subnet CIDRs."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]

  validation {
    condition     = length(var.app_subnet_cidrs) == 2
    error_message = "app_subnet_cidrs must contain exactly 2 CIDR blocks."
  }
}

variable "db_subnet_cidrs" {
  description = "Two private database subnet CIDRs."
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]

  validation {
    condition     = length(var.db_subnet_cidrs) == 2
    error_message = "db_subnet_cidrs must contain exactly 2 CIDR blocks."
  }
}

variable "instance_type" {
  description = "EC2 instance type for app tier."
  type        = string
  default     = "t3.micro"
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances in ASG."
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of EC2 instances in ASG."
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of EC2 instances in ASG."
  type        = number
  default     = 4
}

variable "app_port" {
  description = "Port exposed by the app tier instances."
  type        = number
  default     = 80
}

variable "alb_ingress_cidrs" {
  description = "Allowed IPv4 CIDR blocks for ALB inbound traffic."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_https" {
  description = "Enable HTTPS listener on ALB."
  type        = bool
  default     = false
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for ALB HTTPS listener. Required if enable_https=true."
  type        = string
  default     = null
}

variable "db_engine" {
  description = "RDS engine. Supported: mysql or postgres."
  type        = string
  default     = "mysql"

  validation {
    condition     = contains(["mysql", "postgres"], var.db_engine)
    error_message = "db_engine must be either mysql or postgres."
  }
}

variable "db_engine_version" {
  description = "RDS engine version."
  type        = string
  default     = "8.0"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.small"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS (GB)."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial DB name."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for RDS."
  type        = string
  default     = "appadmin"
}

variable "db_password" {
  description = "Master password for RDS."
  type        = string
  sensitive   = true
}

variable "db_port" {
  description = "Database port. 3306 for MySQL, 5432 for PostgreSQL."
  type        = number
  default     = 3306

  validation {
    condition     = contains([3306, 5432], var.db_port)
    error_message = "db_port must be either 3306 (MySQL) or 5432 (PostgreSQL)."
  }
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on DB deletion (recommended false for production)."
  type        = bool
  default     = true
}

variable "enable_waf" {
  description = "Attach an AWS WAFv2 Web ACL to ALB."
  type        = bool
  default     = true
}

variable "enable_route53_record" {
  description = "Create Route53 alias A record for ALB."
  type        = bool
  default     = false
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID used for alias record."
  type        = string
  default     = null
}

variable "route53_record_name" {
  description = "Record name for ALB alias (e.g., app.example.com)."
  type        = string
  default     = null
}

variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications (optional)."
  type        = string
  default     = null
}
