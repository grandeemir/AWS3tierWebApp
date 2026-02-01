# =============================================================================
# SECURITY GROUPS
# =============================================================================
# Security groups act as virtual firewalls. They control INBOUND and OUTBOUND
# traffic at the instance/subnet level. Rules are stateful: if you allow
# inbound, the response is automatically allowed outbound.
#
# Our flow: User → ALB (public) → EC2 (private). So:
# - ALB SG: Allow 80/443 from internet; allow outbound to EC2.
# - EC2 SG: Allow 80 only from ALB SG; allow outbound to S3 (via VPC endpoint
#   or NAT) and for package updates.
# =============================================================================

# -----------------------------------------------------------------------------
# Security Group: Application Load Balancer
# -----------------------------------------------------------------------------
# The ALB sits in public subnets. It must accept HTTP/HTTPS from anywhere
# (0.0.0.0/0) and forward to EC2. Outbound to EC2 is allowed by default
# (we restrict EC2 inbound to ALB only).
# -----------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for ALB; allows HTTP/HTTPS from internet"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP from anywhere (users browsing the app)
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS if you add TLS later
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound (e.g. to EC2 targets, health checks)
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# -----------------------------------------------------------------------------
# Security Group: EC2 (Auto Scaling instances)
# -----------------------------------------------------------------------------
# EC2 instances live in *private* subnets. They should NOT be directly
# reachable from the internet. Only the ALB can send traffic to them.
# We use source_security_group_id to restrict ingress to the ALB's SG.
# -----------------------------------------------------------------------------

resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for EC2; allow HTTP only from ALB"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP only from the ALB (so users never hit EC2 directly)
  ingress {
    description     = "HTTP from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Allow SSH from VPC only (optional; remove in production or restrict to bastion)
  # Uncomment if you need to debug instances:
  # ingress {
  #   description = "SSH from VPC"
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = [var.vpc_cidr]
  # }

  # Outbound: allow all (needed for yum/apt, S3, etc. via NAT)
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}
