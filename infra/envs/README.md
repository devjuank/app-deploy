# Environment Configurations

## dev
- Wires the reusable modules (VPC, Route53, ACM, IAM, EKS, RDS) into a concrete environment.
- Uses `terraform.tfvars` to capture project-specific inputs such as CIDRs, domain, and scaling settings.
- Produces outputs consumed by the Kubernetes layer (cluster name, certificate ARN, secret ARNs, etc.).
- Includes an AWS Budget to alert when monthly spend crosses the configured threshold.
