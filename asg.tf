# =============================================================================
# AUTO SCALING GROUP (ASG) + EC2 LAUNCH TEMPLATE
# =============================================================================
# ASG maintains a desired number of EC2 instances across AZs. It scales
# based on metrics (CPU, request count, etc.) and registers instances
# with the ALB target group. We use:
# - Data source: AMI lookup (latest Amazon Linux 2023)
# - user_data: bootstrap script to install nginx and a simple homepage
# - IAM instance profile: EC2 can access S3 for static assets
# =============================================================================

# -----------------------------------------------------------------------------
# DATA SOURCE: AMI Lookup
# -----------------------------------------------------------------------------
# Instead of hardcoding an AMI ID (which changes over time), we look up the
# latest Amazon Linux 2023 AMI in the current region. This is a common
# Terraform pattern for EC2.
# =============================================================================

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# -----------------------------------------------------------------------------
# Launch Template
# -----------------------------------------------------------------------------
# Defines the EC2 "blueprint": AMI, instance type, user_data, IAM profile,
# and security groups. The ASG uses this to launch new instances.
# -----------------------------------------------------------------------------

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  vpc_security_group_ids = [aws_security_group.ec2.id]

  # user_data: runs when the instance boots. We install nginx and create a
  # simple index.html. In production, your app would use the IAM role to
  # read static assets from S3 (e.g. CloudFront URLs or direct S3 calls).
  # user_data runs at first boot. Installs nginx, writes a simple page.
  # The instance IAM role allows S3 access; your app would fetch static assets from S3.
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    dnf install -y nginx
    systemctl enable nginx
    {
      echo '<!DOCTYPE html><html><head><title>HA Web App</title></head><body>'
      echo '<h1>Highly Available Web App</h1>'
      echo '<p>User → ALB → EC2 (ASG) → S3 (static assets)</p>'
      echo -n '<p>Instance: '
      curl -s http://169.254.169.254/latest/meta-data/instance-id
      echo '</p></body></html>'
    } > /usr/share/nginx/html/index.html
    systemctl start nginx
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-ec2"
    }
  }

  tags = {
    Name = "${var.project_name}-launch-template"
  }
}

# -----------------------------------------------------------------------------
# Auto Scaling Group
# -----------------------------------------------------------------------------
# - min/max/desired: we use variables for flexibility.
# - vpc_zone_identifier: private subnets only; EC2 never gets a public IP.
# - target_group_arns: ASG auto-registers new instances with the ALB.
# - health_check_type = "ELB": use ALB health checks (not just EC2 status).
# -----------------------------------------------------------------------------

resource "aws_autoscaling_group" "app" {
  name                      = "${var.project_name}-asg"
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_desired_capacity
  vpc_zone_identifier       = aws_subnet.private[*].id
  target_group_arns         = [aws_lb_target_group.app.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 120

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
