# ==============================================================================
# Security Group
# ==============================================================================
resource "aws_security_group" "this" {
  name        = "${var.replication_group_id}-sg"
  description = "Security group for ElastiCache Redis ${var.replication_group_id}"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name      = "${var.replication_group_id}-sg"
    Component = "redis"
  })
}

resource "aws_vpc_security_group_ingress_rule" "allowed" {
  for_each = { for idx, sg_id in var.allowed_security_group_ids : tostring(idx) => sg_id }

  security_group_id            = aws_security_group.this.id
  description                  = "Allow Redis access from ${each.value}"
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
  referenced_security_group_id = each.value
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ==============================================================================
# Subnet Group
# ==============================================================================
resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.replication_group_id}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.common_tags, {
    Name      = "${var.replication_group_id}-subnet-group"
    Component = "redis"
  })
}

# ==============================================================================
# Auth Token (optional)
# ==============================================================================
resource "random_password" "auth_token" {
  count   = var.create_auth_token && var.transit_encryption_enabled ? 1 : 0
  length  = 32
  special = false
}

# ==============================================================================
# ElastiCache Replication Group
# ==============================================================================
resource "aws_elasticache_replication_group" "this" {
  replication_group_id = var.replication_group_id
  description          = "Redis replication group for ${var.replication_group_id}"

  engine             = "redis"
  engine_version     = var.engine_version
  node_type          = var.node_type
  num_cache_clusters = var.num_cache_clusters
  port               = 6379

  subnet_group_name          = aws_elasticache_subnet_group.this.name
  security_group_ids         = [aws_security_group.this.id]
  automatic_failover_enabled = var.automatic_failover_enabled

  transit_encryption_enabled = var.transit_encryption_enabled
  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  auth_token                 = var.create_auth_token && var.transit_encryption_enabled ? random_password.auth_token[0].result : null

  tags = merge(var.common_tags, {
    Name      = var.replication_group_id
    Component = "redis"
  })

  lifecycle {
    precondition {
      condition     = !var.automatic_failover_enabled || var.num_cache_clusters >= 2
      error_message = "automatic_failover_enabled requires at least 2 cache clusters."
    }
  }
}
