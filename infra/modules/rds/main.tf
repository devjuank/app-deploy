locals {
  base_tags = merge({
    Project     = var.project_name,
    Environment = var.environment,
  }, var.tags)

  secret_prefix = "/${var.project_name}/${var.environment}/db"
}

resource "random_password" "master" {
  count   = var.db_password == "" ? 1 : 0
  length  = 24
  special = true
}

locals {
  master_password = var.db_password != "" ? var.db_password : random_password.master[0].result
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-${var.environment}-rds-subnet"
  subnet_ids = var.db_subnet_ids

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-${var.environment}-rds-subnet"
  })
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds"
  description = "Security group for RDS allowing traffic from EKS nodes"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.node_security_group_id]
    description     = "Allow Postgres from EKS workers"
  }

  dynamic "ingress" {
    for_each = var.allowed_cidr_blocks
    content {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "Additional DB access"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  })
}

resource "aws_db_instance" "this" {
  identifier                          = "${var.project_name}-${var.environment}-postgres"
  engine                              = "postgres"
  engine_version                      = var.engine_version
  instance_class                      = var.instance_class
  db_name                             = var.db_name
  username                            = var.db_username
  password                            = local.master_password
  allocated_storage                   = var.allocated_storage
  max_allocated_storage               = var.max_allocated_storage
  storage_encrypted                   = true
  kms_key_id                          = var.kms_key_id
  multi_az                            = var.multi_az
  db_subnet_group_name                = aws_db_subnet_group.this.name
  vpc_security_group_ids              = [aws_security_group.rds.id]
  backup_retention_period             = var.backup_retention_days
  deletion_protection                 = false
  skip_final_snapshot                 = true
  performance_insights_enabled        = true
  performance_insights_kms_key_id     = var.kms_key_id
  auto_minor_version_upgrade          = true
  copy_tags_to_snapshot               = true
  monitoring_interval                 = 0
  apply_immediately                   = true
  iam_database_authentication_enabled = false
  publicly_accessible                 = false

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-${var.environment}-postgres"
  })
}

# Secrets Manager entries consumed by External Secrets
resource "aws_secretsmanager_secret" "db_user" {
  name        = "${local.secret_prefix}/user"
  description = "Database master username for ${var.project_name}-${var.environment}"
  kms_key_id  = var.kms_key_id

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-${var.environment}-db-user"
  })
}

resource "aws_secretsmanager_secret" "db_password" {
  name        = "${local.secret_prefix}/password"
  description = "Database master password for ${var.project_name}-${var.environment}"
  kms_key_id  = var.kms_key_id

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-${var.environment}-db-password"
  })
}

resource "aws_secretsmanager_secret" "db_name" {
  name        = "${local.secret_prefix}/name"
  description = "Database name for ${var.project_name}-${var.environment}"
  kms_key_id  = var.kms_key_id

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-${var.environment}-db-name"
  })
}

resource "aws_secretsmanager_secret" "db_host" {
  name        = "${local.secret_prefix}/host"
  description = "Database host endpoint for ${var.project_name}-${var.environment}"
  kms_key_id  = var.kms_key_id

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-${var.environment}-db-host"
  })
}

resource "aws_secretsmanager_secret_version" "db_user" {
  secret_id     = aws_secretsmanager_secret.db_user.id
  secret_string = var.db_username
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = local.master_password
}

resource "aws_secretsmanager_secret_version" "db_name" {
  secret_id     = aws_secretsmanager_secret.db_name.id
  secret_string = var.db_name
}

resource "aws_secretsmanager_secret_version" "db_host" {
  secret_id     = aws_secretsmanager_secret.db_host.id
  secret_string = aws_db_instance.this.address
}

# Optional RDS Proxy for connection pooling
resource "aws_iam_role" "rds_proxy" {
  count = var.enable_rds_proxy ? 1 : 0

  name = "${var.project_name}-${var.environment}-rds-proxy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "rds.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-${var.environment}-rds-proxy"
  })
}

resource "aws_iam_role_policy_attachment" "rds_proxy" {
  count      = var.enable_rds_proxy ? 1 : 0
  role       = aws_iam_role.rds_proxy[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSProxyServiceRolePolicy"
}

resource "aws_db_proxy" "this" {
  count = var.enable_rds_proxy ? 1 : 0

  name                   = "${var.project_name}-${var.environment}-proxy"
  engine_family          = "POSTGRESQL"
  role_arn               = aws_iam_role.rds_proxy[0].arn
  vpc_security_group_ids = [aws_security_group.rds.id]
  vpc_subnet_ids         = var.db_subnet_ids
  require_tls            = true
  idle_client_timeout    = 1800

  auth {
    auth_scheme = "SECRETS"
    secret_arn  = aws_secretsmanager_secret.db_password.arn
  }

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-${var.environment}-rds-proxy"
  })
}

resource "aws_db_proxy_default_target_group" "this" {
  count = var.enable_rds_proxy ? 1 : 0

  db_proxy_name = aws_db_proxy.this[0].name

  connection_pool_config {
    max_connections_percent      = 90
    max_idle_connections_percent = 50
    connection_borrow_timeout    = 120
  }
}

resource "aws_db_proxy_target" "this" {
  count = var.enable_rds_proxy ? 1 : 0

  db_proxy_name          = aws_db_proxy.this[0].name
  target_group_name      = aws_db_proxy_default_target_group.this[0].name
  db_instance_identifier = aws_db_instance.this.id
}

output "rds_endpoint" {
  description = "Writer endpoint for the RDS instance."
  value       = aws_db_instance.this.address
}

output "rds_reader_endpoint" {
  description = "Reader endpoint (equals writer for single instance)."
  value       = aws_db_instance.this.endpoint
}

output "rds_security_group_id" {
  description = "Security group protecting the RDS instance."
  value       = aws_security_group.rds.id
}

output "secrets" {
  description = "Secrets Manager ARNs for database credentials."
  value = {
    user     = aws_secretsmanager_secret.db_user.arn
    password = aws_secretsmanager_secret.db_password.arn
    name     = aws_secretsmanager_secret.db_name.arn
    host     = aws_secretsmanager_secret.db_host.arn
  }
}

output "proxy_endpoint" {
  description = "Endpoint of the optional RDS Proxy. Empty if disabled."
  value       = var.enable_rds_proxy ? aws_db_proxy.this[0].endpoint : null
}
