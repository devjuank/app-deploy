variable "project_name" {
  description = "Project identifier used for naming and tagging."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev)."
  type        = string
}

variable "cluster_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.29"
}

variable "vpc_id" {
  description = "ID of the VPC hosting the cluster."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for worker nodes."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for load balancers."
  type        = list(string)
}

variable "allowed_cidrs_admin" {
  description = "CIDRs allowed to reach the EKS public API endpoint."
  type        = list(string)
}

variable "cluster_role_arn" {
  description = "IAM role ARN assumed by the EKS control plane."
  type        = string
}

variable "node_role_arn" {
  description = "IAM role ARN assumed by all managed node groups."
  type        = string
}

variable "eks_on_demand_min" {
  description = "Minimum (and desired) capacity for the on-demand node group."
  type        = number
  default     = 1
}

variable "eks_on_demand_max" {
  description = "Maximum capacity for the on-demand node group."
  type        = number
  default     = 3
}

variable "eks_spot_min" {
  description = "Minimum (and desired) capacity for the Spot node group."
  type        = number
  default     = 2
}

variable "eks_spot_max" {
  description = "Maximum capacity for the Spot node group."
  type        = number
  default     = 6
}

variable "node_instance_type" {
  description = "EC2 instance type used for the worker nodes."
  type        = string
  default     = "t3.medium"
}

variable "node_disk_size" {
  description = "Disk size in GiB for worker nodes."
  type        = number
  default     = 50
}

variable "tags" {
  description = "Additional tags to propagate to resources."
  type        = map(string)
  default     = {}
}
