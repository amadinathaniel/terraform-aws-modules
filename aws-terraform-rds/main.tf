# ==============================================================================
# Security Group
# ==============================================================================
resource "aws_security_group" "this" {
  name        = "${var.identifier}-sg"
  description = "Security group for RDS instance ${var.identifier}"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name      = "${var.identifier}-sg"
    Component = "rds"
  })
}

resource "aws_vpc_security_group_ingress_rule" "allowed" {
  count = 0 #for_each = toset(var.allowed_security_group_ids)

  security_group_id            = aws_security_group.this.id
  description                  = "Allow PostgreSQL access from ${each.value}"
  from_port                    = 5432
  to_port                      = 5432
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
# DB Subnet Group
# ==============================================================================
resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.common_tags, {
    Name      = "${var.identifier}-subnet-group"
    Component = "rds"
  })
}

# ==============================================================================
# Master User Password (stored in Secrets Manager)
# ==============================================================================
resource "random_password" "master" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "master_password" {
  name                    = "${var.identifier}/postgres"
  recovery_window_in_days = 0

  tags = merge(var.common_tags, {
    Name      = "${var.identifier}/postgres"
    Component = "rds"
  })
}

resource "aws_secretsmanager_secret_version" "master_password" {
  secret_id = aws_secretsmanager_secret.master_password.id
  secret_string = jsonencode({
    POSTGRES_USER     = var.username
    POSTGRES_PASSWORD = random_password.master.result
    POSTGRES_HOST     = aws_db_instance.this.address
    POSTGRES_PORT     = aws_db_instance.this.port
    POSTGRES_DB       = var.db_name
  })
}

# ==============================================================================
# RDS Instance
# ==============================================================================
resource "aws_db_instance" "this" {
  identifier     = var.identifier
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = var.db_name
  username = var.username

  password = random_password.master.result

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  publicly_accessible    = false

  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = true
  final_snapshot_identifier = "${var.identifier}-final-snapshot"
  copy_tags_to_snapshot     = true

  performance_insights_enabled = var.performance_insights_enabled

  tags = merge(var.common_tags, {
    Name      = var.identifier
    Component = "rds"
  })
}
