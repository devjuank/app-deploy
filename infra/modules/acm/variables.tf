variable "project_name" {
  description = "Project identifier for naming and tagging."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev)."
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID used for DNS validation."
  type        = string
}

variable "hosted_zone_name" {
  description = "Root domain name (e.g. example.com)."
  type        = string
}

variable "subdomain" {
  description = "Subdomain prefix (e.g. dev) used to form app.dev.example.com."
  type        = string
}

variable "additional_sans" {
  description = "Optional subject alternative names for the certificate."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags for ACM resources."
  type        = map(string)
  default     = {}
}
