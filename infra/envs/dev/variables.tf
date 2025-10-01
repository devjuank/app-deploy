variable "project_name" {
  description = "Project identifier used for naming and tagging."
  type        = string
}

variable "environment" {
  description = "Optional environment override (defaults to subdomain)."
  type        = string
  default     = null
}

variable "region" {
  description = "AWS region for all resources."
  type        = string
}

variable "owner" {
  description = "Owner tag value."
  type        = string
}

variable "cost_center" {
  description = "Cost center tag value."
  type        = string
}

variable "additional_tags" {
  description = "Extra tags to propagate to resources."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "hosted_zone_name" {
  description = "Root DNS zone (e.g. example.com)."
  type        = string
}

variable "subdomain" {
  description = "Subdomain prefix used for the environment (e.g. dev)."
  type        = string
}

variable "allowed_cidrs_admin" {
  description = "CIDR blocks allowed to access the EKS API endpoint."
  type        = list(string)
}

variable "cluster_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.29"
}

variable "eks_on_demand_min" {
  description = "Minimum (and desired) size of the on-demand node group."
  type        = number
  default     = 1
}

variable "eks_on_demand_max" {
  description = "Maximum size of the on-demand node group."
  type        = number
  default     = 3
}

variable "eks_spot_min" {
  description = "Minimum (and desired) size of the Spot node group."
  type        = number
  default     = 2
}

variable "eks_spot_max" {
  description = "Maximum size of the Spot node group."
  type        = number
  default     = 6
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes."
  type        = string
  default     = "t3.medium"
}

variable "node_disk_size" {
  description = "Disk size for each worker node (GiB)."
  type        = number
  default     = 50
}

variable "rds_instance_class" {
  description = "Instance class for the PostgreSQL instance."
  type        = string
  default     = "db.t3.medium"
}

variable "rds_engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "15.5"
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ deployment for RDS."
  type        = bool
  default     = true
}

variable "rds_allocated_storage" {
  description = "Initial storage allocation for RDS (GiB)."
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Maximum storage autoscaling limit for RDS (GiB)."
  type        = number
  default     = 100
}

variable "rds_db_name" {
  description = "Initial database name."
  type        = string
}

variable "rds_db_username" {
  description = "Master username for the Postgres instance."
  type        = string
}

variable "rds_db_password" {
  description = "Optional master password (leave blank to autogenerate)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "rds_backup_retention_days" {
  description = "Number of days to retain automated RDS backups."
  type        = number
  default     = 7
}

variable "enable_rds_proxy" {
  description = "Whether to create an RDS Proxy."
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "Optional KMS key ARN for encrypting RDS and secrets."
  type        = string
  default     = null
}

variable "allowed_cidrs_db_extra" {
  description = "Additional CIDR blocks allowed to reach the database."
  type        = list(string)
  default     = []
}

variable "budget_limit_usd" {
  description = "Monthly cost threshold that triggers budget alerts."
  type        = number
  default     = 50
}

variable "budget_notification_email" {
  description = "Email address that receives AWS Budget alerts."
  type        = string
}
