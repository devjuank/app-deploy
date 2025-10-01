# Kubernetes Add-ons

## AWS Load Balancer Controller
- Deploys the controller with IRSA.
- Required for ALB-backed ingress and ACM TLS termination.

## ExternalDNS
- Syncs Kubernetes ingress/Service records to Route53.
- Uses IRSA and domain filters to manage only the hosted zone.

## Cluster Autoscaler
- Scales EKS node groups based on pending pods.
- Configured with RBAC annotations for its IAM role.

## External Secrets Operator
- Namespace, service account, and ClusterSecretStore for AWS Secrets Manager.
- Example `ExternalSecret` exposes `/project/env/db/*` credentials to Kubernetes.
