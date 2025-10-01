# Kubernetes Manifests

## Structure
- `addons/`: Helm overrides for controllers (ALB, external-dns, cluster-autoscaler) plus External Secrets manifests.
- `apps/wordpress/`: chart overrides and supporting resources (HPA, PDB, Ingress, NetworkPolicy) for the application.

## Workflow
1. Export variables from `terraform output` (`CLUSTER_NAME`, IRSA roles, `ACM_CERT_ARN`, etc.).
2. Render each chart with `envsubst` and deploy via `helm upgrade --install`.
3. Apply non-Helm manifests (`external-secrets`, `networkpolicy`, etc.) with `kubectl apply`.
4. Verify state (`kubectl get deploy -A`, `kubectl get hpa -n app`).

## Notes
- Files contain `${VAR}` placeholders suited for `envsubst`.
- External Secrets expects AWS Secrets Manager entries under `/project/env/db/*`.
- The NetworkPolicy restricts egress to DNS, HTTPS, and the database; update `RDS_HOST_CIDR` before applying.
