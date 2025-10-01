# app – Deployment Guide

This guide links the Terraform infrastructure and Kubernetes manifests required to run the WordPress reference workload in AWS. Use it as the master entry point and drill into the component-specific docs when you need full detail.

## Document Map
- [`../infra/README.md`](../infra/README.md) – Terraform module structure, workflow, and notes.
- [`../infra/envs/README.md`](../infra/envs/README.md) – Environment-specific wiring (currently `dev`).
- [`../k8s/README.md`](../k8s/README.md) – Kubernetes deployment workflow.
- [`../k8s/addons/README.md`](../k8s/addons/README.md) – Add-on controllers overview.
- [`../k8s/apps/README.md`](../k8s/apps/README.md) – WordPress chart customisations.

## Prerequisites
- Terraform ≥ 1.5, Helm ≥ 3.10, kubectl, AWS CLI v2, `jq`, `envsubst`.
- AWS account with rights over IAM, EKS, EC2, Route 53, ACM, RDS, Budgets, Secrets Manager in `us-east-1`.
- (Optional) Remote Terraform backend (S3 + DynamoDB) configured before `terraform init`.
- Authenticated AWS session (`aws sso login` o variables de entorno).

## High-Level Flow
1. **Provision infrastructure** – Follow `infra/README.md`; run Terraform from `infra/envs/dev` and record outputs (`cluster_name`, IRSA role ARNs, `acm_certificate_arn`, Secrets prefixes, etc.).
2. **Prepare kubeconfig** – `aws eks update-kubeconfig --name <cluster> --region us-east-1` using the Terraform outputs.
3. **Install add-ons** – Use `k8s/README.md` to install ALB controller, ExternalDNS, Cluster Autoscaler, and External Secrets via `envsubst` + `helm upgrade` / `kubectl apply`.
4. **Deploy application** – Install WordPress with the provided overrides and apply supporting manifests (HPA, PDB, Ingress, NetworkPolicy).
5. **Validate** – Complete the checklist below to confirm DNS/TLS, database connectivity, scaling, and security controls.

## Validation Checklist
- **DNS & TLS** – `curl -I https://app.<env>.<domain>` returns 200 with ACM certificate issued.
- **Database HA** – `aws rds describe-db-instances` shows Multi-AZ; create/read posts in WordPress.
- **Scaling** – `kubectl get hpa -n app`; generate load (`hey -z 2m -c 20 ...`) and observe replica/node scale-outs.
- **Security** – RDS SG only allows the EKS node SG; IRSA annotations present on service accounts; `kubectl exec ... -- nc -zv 1.1.1.1 80` fails due to NetworkPolicy.
- **Observability** – CloudWatch log group `/aws/eks/<cluster>/cluster` exists; `kubectl top pods` reports metrics.

## Teardown Checklist
1. `helm uninstall blog -n app` and delete the namespace.
2. Remove add-ons: `helm uninstall aws-load-balancer-controller external-dns cluster-autoscaler -n kube-system` and delete the `external-secrets` namespace.
3. Wait for the ALB to be deleted (no listeners/target groups left).
4. Run `terraform destroy` from `infra/envs/dev`.

