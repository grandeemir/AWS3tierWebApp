# =============================================================================
# VPC (Virtual Private Cloud)
# =============================================================================
# A VPC is your own isolated network in AWS. All resources (EC2, ALB, etc.)
# live inside a VPC. This one spans 2 AZs for high availability.
# =============================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true # Required for ALB and private DNS resolution
  enable_dns_support   = true # Enables DNS resolution via Route 53 Resolver

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# =============================================================================
# INTERNET GATEWAY (IGW)
# =============================================================================
# Attached to the VPC. Allows traffic between the VPC and the public internet.
# Resources in *public* subnets with a route to the IGW can be reached from
# the internet (e.g. ALB, NAT Gateway, Bastion).
# =============================================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# =============================================================================
# SUBNETS — USING count
# =============================================================================
# We create 2 public + 2 private subnets (one per AZ).
# count = length(var.availability_zones) loops over AZs.
# cidrsubnet() splits the VPC CIDR into /20 chunks:
#   - Public:  10.0.0.0/20, 10.0.16.0/20
#   - Private: 10.0.128.0/20, 10.0.144.0/20
# =============================================================================

# --- Public subnets (for ALB, NAT Gateway) ---
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index) # 4-bit shift → /20
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true # EC2 in this subnet gets a public IP (we use private; this is for NAT)

  tags = {
    Name = "${var.project_name}-public-${var.availability_zones[count.index]}"
    Type = "public"
  }
}

# --- Private subnets (for EC2 / Auto Scaling) ---
resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index + 8) # Offset +8 to avoid overlap
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false # No public IP; outbound via NAT

  tags = {
    Name = "${var.project_name}-private-${var.availability_zones[count.index]}"
    Type = "private"
  }
}

# =============================================================================
# ELASTIC IPs FOR NAT GATEWAYS
# =============================================================================
# Each NAT Gateway needs an EIP. We use one NAT per AZ for HA (optional:
# single NAT is cheaper but less resilient).
# =============================================================================

resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-${var.availability_zones[count.index]}"
  }

  depends_on = [aws_internet_gateway.main]
}

# =============================================================================
# NAT GATEWAYS (one per AZ)
# =============================================================================
# Placed in *public* subnets. Private subnet instances use NAT to reach
# internet (updates, S3, etc.) while remaining non-routable from internet.
# =============================================================================

resource "aws_nat_gateway" "main" {
  count = length(var.availability_zones)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.project_name}-nat-${var.availability_zones[count.index]}"
  }

  depends_on = [aws_internet_gateway.main]
}

# =============================================================================
# ROUTE TABLES
# =============================================================================
# Routes determine where traffic is sent. Public RT → IGW; Private RT → NAT.
# =============================================================================

# --- Public route table: send 0.0.0.0/0 to Internet Gateway ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Associate each public subnet with the public route table
resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- Private route tables — USING for_each (one per AZ) ---
# for_each iterates over a map/set. We use it to create one private RT per AZ,
# each with a route to that AZ's NAT Gateway. This is a common pattern.
# =============================================================================

locals {
  # Map AZ name -> NAT Gateway ID for for_each
  az_to_nat = {
    for i in range(length(var.availability_zones)) :
    var.availability_zones[i] => aws_nat_gateway.main[i].id
  }
}

resource "aws_route_table" "private" {
  for_each = local.az_to_nat

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = each.value
  }

  tags = {
    Name = "${var.project_name}-private-rt-${each.key}"
  }
}

# Associate each private subnet with its AZ's private route table
resource "aws_route_table_association" "private" {
  for_each = {
    for i in range(length(var.availability_zones)) :
    var.availability_zones[i] => {
      subnet_id = aws_subnet.private[i].id
      az        = var.availability_zones[i]
    }
  }

  subnet_id      = each.value.subnet_id
  route_table_id = aws_route_table.private[each.value.az].id
}
