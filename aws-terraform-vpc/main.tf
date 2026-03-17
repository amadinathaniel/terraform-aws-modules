# ------------------------------------------------------------------------------
# VPC
# ------------------------------------------------------------------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name      = "${var.project_name}-${var.environment}-vpc"
    Component = "network"
  })
}

# ------------------------------------------------------------------------------
# Internet Gateway
# ------------------------------------------------------------------------------
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.common_tags, {
    Name      = "${var.project_name}-${var.environment}-igw"
    Component = "network"
  })
}

# ------------------------------------------------------------------------------
# Public Subnets
# ------------------------------------------------------------------------------
resource "aws_subnet" "public" {
  for_each = { for index, availability_zone in var.availability_zones : availability_zone => var.public_subnet_cidrs[index] }

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    { for name in var.cluster_names : "kubernetes.io/cluster/${name}" => "shared" },
    {
      Name      = "${var.project_name}-${var.environment}-public-${each.key}"
      Component = "network"
    },
    length(var.cluster_names) > 0 ? { "kubernetes.io/role/elb" = "1" } : {}
  )
}

# ------------------------------------------------------------------------------
# Private Subnets
# ------------------------------------------------------------------------------
resource "aws_subnet" "private" {
  for_each = { for index, availability_zone in var.availability_zones : availability_zone => var.private_subnet_cidrs[index] }

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = merge(
    var.common_tags,
    { for name in var.cluster_names : "kubernetes.io/cluster/${name}" => "shared" },
    {
      Name      = "${var.project_name}-${var.environment}-private-${each.key}"
      Component = "network"
    },
    length(var.cluster_names) > 0 ? { "kubernetes.io/role/internal-elb" = "1" } : {}
  )
}

# ------------------------------------------------------------------------------
# Database Subnets
# ------------------------------------------------------------------------------
resource "aws_subnet" "database" {
  for_each = { for index, availability_zone in var.availability_zones : availability_zone => var.database_subnet_cidrs[index] if length(var.database_subnet_cidrs) > 0 }

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = merge(var.common_tags, {
    Name      = "${var.project_name}-${var.environment}-database-${each.key}"
    Component = "network"
  })
}

# ------------------------------------------------------------------------------
# Cache Subnets
# ------------------------------------------------------------------------------
resource "aws_subnet" "cache" {
  for_each = { for index, availability_zone in var.availability_zones : availability_zone => var.cache_subnet_cidrs[index] if length(var.cache_subnet_cidrs) > 0 }

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = merge(var.common_tags, {
    Name      = "${var.project_name}-${var.environment}-cache-${each.key}"
    Component = "network"
  })
}

# ------------------------------------------------------------------------------
# NAT Gateway(s)
# ------------------------------------------------------------------------------
resource "aws_eip" "nat" {
  count  = var.single_nat_gateway ? 1 : length(var.availability_zones)
  domain = "vpc"

  tags = merge(var.common_tags, {
    Name      = var.single_nat_gateway ? "${var.project_name}-${var.environment}-nat-eip" : "${var.project_name}-${var.environment}-nat-eip-${var.availability_zones[count.index]}"
    Component = "network"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count         = var.single_nat_gateway ? 1 : length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[var.availability_zones[count.index]].id

  tags = merge(var.common_tags, {
    Name      = var.single_nat_gateway ? "${var.project_name}-${var.environment}-natgw" : "${var.project_name}-${var.environment}-natgw-${var.availability_zones[count.index]}"
    Component = "network"
  })

  depends_on = [aws_internet_gateway.this]
}

# ------------------------------------------------------------------------------
# Public Route Table
# ------------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.common_tags, {
    Name      = "${var.project_name}-${var.environment}-public-rt"
    Component = "network"
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

# ------------------------------------------------------------------------------
# Private Route Table(s)
# ------------------------------------------------------------------------------
resource "aws_route_table" "private" {
  count  = var.single_nat_gateway ? 1 : length(var.availability_zones)
  vpc_id = aws_vpc.this.id

  tags = merge(var.common_tags, {
    Name      = var.single_nat_gateway ? "${var.project_name}-${var.environment}-private-rt" : "${var.project_name}-${var.environment}-private-rt-${var.availability_zones[count.index]}"
    Component = "network"
  })
}

resource "aws_route" "private_nat" {
  count                  = var.single_nat_gateway ? 1 : length(var.availability_zones)
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[var.single_nat_gateway ? 0 : count.index].id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[var.single_nat_gateway ? 0 : index(var.availability_zones, each.key)].id
}

# ------------------------------------------------------------------------------
# Database Route Table
# ------------------------------------------------------------------------------
resource "aws_route_table" "database" {
  count  = length(var.database_subnet_cidrs) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = merge(var.common_tags, {
    Name      = "${var.project_name}-${var.environment}-database-rt"
    Component = "network"
  })
}

resource "aws_route_table_association" "database" {
  for_each = aws_subnet.database

  subnet_id      = each.value.id
  route_table_id = aws_route_table.database[0].id
}

# ------------------------------------------------------------------------------
# Cache Route Table
# ------------------------------------------------------------------------------
resource "aws_route_table" "cache" {
  count  = length(var.cache_subnet_cidrs) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = merge(var.common_tags, {
    Name      = "${var.project_name}-${var.environment}-cache-rt"
    Component = "network"
  })
}

resource "aws_route_table_association" "cache" {
  for_each = aws_subnet.cache

  subnet_id      = each.value.id
  route_table_id = aws_route_table.cache[0].id
}

# ------------------------------------------------------------------------------
# DB Subnet Group
# ------------------------------------------------------------------------------
resource "aws_db_subnet_group" "this" {
  count      = length(var.database_subnet_cidrs) > 0 ? 1 : 0
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = [for s in aws_subnet.database : s.id]

  tags = merge(var.common_tags, {
    Name      = "${var.project_name}-${var.environment}-db-subnet-group"
    Component = "network"
  })
}

# ------------------------------------------------------------------------------
# ElastiCache Subnet Group
# ------------------------------------------------------------------------------
resource "aws_elasticache_subnet_group" "this" {
  count      = length(var.cache_subnet_cidrs) > 0 ? 1 : 0
  name       = "${var.project_name}-${var.environment}-cache-subnet-group"
  subnet_ids = [for s in aws_subnet.cache : s.id]

  tags = merge(var.common_tags, {
    Name      = "${var.project_name}-${var.environment}-cache-subnet-group"
    Component = "network"
  })
}
