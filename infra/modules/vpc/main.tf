data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Split VPC CIDR into equal public/private subnets per AZ.
  public_subnet_cidrs  = [for idx in range(length(local.azs)) : cidrsubnet(var.vpc_cidr, 4, idx)]
  private_subnet_cidrs = [for idx in range(length(local.azs)) : cidrsubnet(var.vpc_cidr, 4, idx + length(local.azs))]

  base_tags = merge({
    Project     = var.project_name,
    Environment = var.environment,
  }, var.tags)
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}

resource "aws_subnet" "public" {
  for_each = { for idx, az in local.azs : az => {
    az   = az
    cidr = local.public_subnet_cidrs[idx]
  } }

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value.az
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = true

  tags = merge(local.base_tags, {
    Name                                                           = "${var.project_name}-${var.environment}-public-${each.value.az}"
    "kubernetes.io/role/elb"                                       = "1"
    "kubernetes.io/cluster/${var.project_name}-${var.environment}" = "shared"
  })
}

resource "aws_subnet" "private" {
  for_each = { for idx, az in local.azs : az => {
    az   = az
    cidr = local.private_subnet_cidrs[idx]
  } }

  vpc_id            = aws_vpc.this.id
  availability_zone = each.value.az
  cidr_block        = each.value.cidr

  tags = merge(local.base_tags, {
    Name                                                           = "${var.project_name}-${var.environment}-private-${each.value.az}"
    "kubernetes.io/role/internal-elb"                              = "1"
    "kubernetes.io/cluster/${var.project_name}-${var.environment}" = "shared"
  })
}

resource "aws_eip" "nat" {
  for_each = aws_subnet.public

  domain = "vpc"

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-${var.environment}-nat-eip-${each.key}"
  })
}

resource "aws_nat_gateway" "this" {
  for_each = aws_subnet.public

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-${var.environment}-nat-${each.key}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  for_each = aws_nat_gateway.this

  vpc_id = aws_vpc.this.id

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-${var.environment}-private-rt-${each.key}"
  })
}

resource "aws_route" "private_outbound" {
  for_each = aws_route_table.private

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.key].id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}
