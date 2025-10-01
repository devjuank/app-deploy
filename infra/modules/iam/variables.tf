variable "project_name" {
  description = "Project identifier used for naming and tagging."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev)."
  type        = string
}

variable "tags" {
  description = "Additional tags for IAM resources."
  type        = map(string)
  default     = {}
}

variable "oidc_provider_arn" {
  description = "ARN for the EKS OIDC provider (required for IRSA roles)."
  type        = string
  default     = null
}

variable "oidc_provider_url" {
  description = "Issuer URL for the EKS OIDC provider."
  type        = string
  default     = null
}

variable "account_id" {
  description = "AWS account ID hosting the infrastructure."
  type        = string
}

variable "create_cluster_role" {
  description = "Whether to create the EKS control plane IAM role."
  type        = bool
  default     = true
}

variable "create_node_role" {
  description = "Whether to create the EKS worker node IAM role."
  type        = bool
  default     = true
}

variable "enable_irsa" {
  description = "Whether to create IAM roles for service accounts (requires OIDC configuration)."
  type        = bool
  default     = true
}
