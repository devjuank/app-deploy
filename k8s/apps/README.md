# Kubernetes Applications

## WordPress
- Helm overrides disable the bundled MariaDB and point to external PostgreSQL credentials managed by External Secrets.
- Additional manifests provide HPA (CPU 60%, 2-10 replicas), PodDisruptionBudget, ALB Ingress with ACM certificate, and a restrictive NetworkPolicy (DNS, HTTPS, RDS only).
