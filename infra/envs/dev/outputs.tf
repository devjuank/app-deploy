output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate" {
  description = "Cluster certificate authority data"
  value       = module.eks.cluster_certificate
}

output "node_security_group_id" {
  description = "Security group ID for worker nodes"
  value       = module.eks.node_security_group_id
}

output "rds_endpoint" {
  description = "Primary RDS endpoint"
  value       = module.rds.rds_endpoint
}

output "rds_secrets" {
  description = "Secrets Manager ARNs for database values"
  value       = module.rds.secrets
}

output "route53_zone_id" {
  description = "Hosted zone ID"
  value       = module.route53.zone_id
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN for the application domain"
  value       = module.acm.certificate_arn
}

output "irsa_role_arns" {
  description = "Map of IRSA IAM roles"
  value       = module.iam_irsa.irsa_role_arns
}

output "vpc_id" {
  description = "VPC ID hosting the cluster"
  value       = module.vpc.vpc_id
}
