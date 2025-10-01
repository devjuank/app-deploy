variable "project_name" {
  description = "Project identifier used for naming and tagging."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev)."
  type        = string
}

variable "db_subnet_ids" {
  description = "Private subnet IDs for the RDS subnet group."
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID to associate with the RDS security group."
  type        = string
}

variable "node_security_group_id" {
  description = "Security group ID of the EKS worker nodes allowed to reach the database."
  type        = string
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.medium"
}

variable "engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "15.5"
}

variable "multi_az" {
  description = "Whether to enable Multi-AZ for the RDS instance."
  type        = bool
  default     = true
}

variable "allocated_storage" {
  description = "Initial allocated storage (GiB)."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage for autoscaling (GiB)."
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Initial database name."
  type        = string
}

variable "db_username" {
  description = "Master username for the database."
  type        = string
}

variable "db_password" {
  description = "Master password for the database (leave blank to autogenerate)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "backup_retention_days" {
  description = "Number of days to retain automated backups."
  type        = number
  default     = 7
}

variable "enable_rds_proxy" {
  description = "Whether to create an RDS Proxy in front of the instance."
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "Optional KMS key ARN for encrypting storage and Secrets Manager entries."
  type        = string
  default     = null
}

variable "allowed_cidr_blocks" {
  description = "Additional CIDRs allowed to reach the database (beyond the node SG)."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to propagate."
  type        = map(string)
  default     = {}
}
