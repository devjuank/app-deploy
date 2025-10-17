terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  environment = coalesce(var.environment, var.subdomain, "dev")
  base_tags = merge({
    Project     = var.project_name,
    Environment = local.environment,
    Owner       = var.owner,
    CostCenter  = var.cost_center,
  }, var.additional_tags)
}

module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  environment  = local.environment
  vpc_cidr     = var.vpc_cidr
  az_count     = 3
  tags         = local.base_tags
}

data "aws_route53_zone" "primary" {
  name         = var.hosted_zone_name
  private_zone = false
}

module "acm" {
  source = "../../modules/acm"

  project_name     = var.project_name
  environment      = local.environment
  hosted_zone_id   = data.aws_route53_zone.primary.zone_id
  hosted_zone_name = var.hosted_zone_name
  subdomain        = var.subdomain
  tags             = local.base_tags
}

module "iam_base" {
  source = "../../modules/iam"

  project_name        = var.project_name
  environment         = local.environment
  account_id          = data.aws_caller_identity.current.account_id
  tags                = local.base_tags
  create_cluster_role = true
  create_node_role    = true
  enable_irsa         = false
}

module "eks" {
  source = "../../modules/eks"

  project_name        = var.project_name
  environment         = local.environment
  cluster_version     = var.cluster_version
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  public_subnet_ids   = module.vpc.public_subnet_ids
  allowed_cidrs_admin = var.allowed_cidrs_admin
  cluster_role_arn    = module.iam_base.cluster_role_arn
  node_role_arn       = module.iam_base.node_role_arn
  eks_on_demand_min   = var.eks_on_demand_min
  eks_on_demand_max   = var.eks_on_demand_max
  eks_spot_min        = var.eks_spot_min
  eks_spot_max        = var.eks_spot_max
  node_instance_type  = var.node_instance_type
  node_disk_size      = var.node_disk_size
  tags                = local.base_tags
}

module "iam_irsa" {
  source = "../../modules/iam"

  project_name        = var.project_name
  environment         = local.environment
  account_id          = data.aws_caller_identity.current.account_id
  tags                = local.base_tags
  create_cluster_role = false
  create_node_role    = false
  enable_irsa         = true
  oidc_provider_arn   = module.eks.oidc_provider_arn
  oidc_provider_url   = module.eks.oidc_provider_url
}

module "rds" {
  source = "../../modules/rds"

  project_name           = var.project_name
  environment            = local.environment
  db_subnet_ids          = module.vpc.private_subnet_ids
  vpc_id                 = module.vpc.vpc_id
  node_security_group_id = module.eks.node_security_group_id
  instance_class         = var.rds_instance_class
  engine_version         = var.rds_engine_version
  multi_az               = var.rds_multi_az
  allocated_storage      = var.rds_allocated_storage
  max_allocated_storage  = var.rds_max_allocated_storage
  db_name                = var.rds_db_name
  db_username            = var.rds_db_username
  db_password            = var.rds_db_password
  backup_retention_days  = var.rds_backup_retention_days
  enable_rds_proxy       = var.enable_rds_proxy
  kms_key_id             = var.kms_key_id
  allowed_cidr_blocks    = var.allowed_cidrs_db_extra
  tags                   = local.base_tags
}

resource "aws_budgets_budget" "monthly" {
  name              = "${var.project_name}-${local.environment}-monthly"
  budget_type       = "COST"
  limit_amount      = format("%.2f", var.budget_limit_usd)
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = formatdate("2006-01-02_15:04", timestamp())

  cost_types {
    include_credit             = true
    include_discount           = true
    include_other_subscription = true
    include_recurring          = true
    include_refund             = true
    include_subscription       = true
    include_support            = true
    include_tax                = true
    include_upfront            = true
    use_blended                = false
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "FORECASTED"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = [var.budget_notification_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "ACTUAL"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = [var.budget_notification_email]
  }
}
