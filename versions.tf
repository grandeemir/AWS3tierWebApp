# =============================================================================
# TERRAFORM & PROVIDER VERSIONS
# =============================================================================
# This block locks Terraform and provider versions for consistent, reproducible
# deployments. Pinning versions prevents unexpected breaking changes.
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# =============================================================================
# AWS PROVIDER CONFIGURATION
# =============================================================================
# Configures how Terraform communicates with AWS API.
# - region: Where resources are created (use variable for flexibility).
# - default_tags: Applied to ALL resources created by this provider.
#   Helps identify resources in AWS Console (e.g. billing, cost allocation).
# =============================================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "ha-web-app"
      ManagedBy   = "terraform"
      Environment = var.environment
    }
  }
}
