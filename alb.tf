# =============================================================================
# APPLICATION LOAD BALANCER (ALB)
# =============================================================================
# The ALB distributes incoming HTTP/HTTPS traffic across EC2 instances in
# the Auto Scaling Group. It lives in *public* subnets so users can reach it.
# Flow: User → ALB → Target Group → EC2 instances (in private subnets).
# =============================================================================

# -----------------------------------------------------------------------------
# ALB
# -----------------------------------------------------------------------------
# - internal = false: publicly accessible (has a public DNS name).
# - subnets: we use public subnets (one per AZ) for HA.
# - security_groups: only allow 80/443 in (see security-groups.tf).
# -----------------------------------------------------------------------------

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false # Set true in production

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# -----------------------------------------------------------------------------
# Target Group
# -----------------------------------------------------------------------------
# The target group defines *how* the ALB checks health and *where* to send
# traffic. Targets are EC2 instances registered by the ASG.
# - port 80: ALB forwards HTTP to instances on 80.
# - protocol HTTP: we use HTTP for simplicity (add HTTPS + cert in prod).
# - vpc_id: target group must be in the same VPC as targets.
# -----------------------------------------------------------------------------

resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

# -----------------------------------------------------------------------------
# ALB Listener (HTTP)
# -----------------------------------------------------------------------------
# Listener binds a port on the ALB to a target group. When a request
# arrives on port 80, forward it to the app target group.
# =============================================================================

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
