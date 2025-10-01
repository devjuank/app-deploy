variable "project_name" {
  description = "Project identifier for tagging."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)."
  type        = string
}

variable "hosted_zone_name" {
  description = "Root domain name (e.g. example.com)."
  type        = string
}

variable "tags" {
  description = "Additional tags for Route53 resources."
  type        = map(string)
  default     = {}
}
