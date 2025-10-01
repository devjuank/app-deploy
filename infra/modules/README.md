# Infra Modules Overview

## vpc
- Creates a `/16` VPC across the requested AZ count (default 3).
- Provisions public subnets (for ALB) and private subnets (for EKS/RDS) with Kubernetes tags.
- Attaches an Internet Gateway, allocates one NAT Gateway per AZ, and sets corresponding route tables.

## route53
- Manages a public hosted zone for the supplied root domain.
- Exposes the zone ID and nameservers for DNS delegation.

## acm
- Requests an ACM certificate for `app.<subdomain>.<domain>` plus optional SANs.
- Automates DNS validation in the provided Route53 zone before exposing the certificate ARN.
