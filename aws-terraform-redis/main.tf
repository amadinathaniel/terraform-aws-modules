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
  count = 0 # for_each = toset(var.allowed_security_group_ids)

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

resource "aws_secretsmanager_secret" "auth_token" {
  count                   = var.create_auth_token && var.transit_encryption_enabled ? 1 : 0
  name                    = "${var.replication_group_id}/redis"
  recovery_window_in_days = 0

  tags = merge(var.common_tags, {
    Name      = "${var.replication_group_id}/redis"
    Component = "redis"
  })
}

resource "aws_secretsmanager_secret_version" "auth_token" {
  count     = var.create_auth_token && var.transit_encryption_enabled ? 1 : 0
  secret_id = aws_secretsmanager_secret.auth_token[0].id
  secret_string = jsonencode({
    REDIS_PASSWORD = random_password.auth_token[0].result
    REDIS_HOST     = aws_elasticache_replication_group.this.primary_endpoint_address
    REDIS_PORT     = 6379
  })
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
  multi_az_enabled           = var.multi_az_enabled

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
    precondition {
      condition     = !var.multi_az_enabled || (var.automatic_failover_enabled && var.num_cache_clusters >= 2)
      error_message = "multi_az_enabled requires automatic_failover_enabled and at least 2 cache clusters."
    }
  }
}
