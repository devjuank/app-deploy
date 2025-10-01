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

## eks
- Stitches the EKS control plane with managed node groups (1 on-demand, 1 Spot) across private subnets.
- Configures security groups, control-plane logging, and the cluster OIDC provider needed for IRSA.
- Exposes cluster metadata (endpoint, CA, node SG) for kubeconfig generation and downstream modules.

## iam
- Creates the EKS control plane and node roles with required AWS managed policies.
- When IRSA is enabled, provisions service-account roles for ALB Controller, ExternalDNS, External Secrets, and Cluster Autoscaler with least-privilege policies.
- Emits ARNs so Helm add-ons can annotate their service accounts appropriately.
