# Terraform Infrastructure

## Structure
- `modules/`: reusable components (VPC, Route53, ACM, IAM, EKS, RDS).
- `envs/dev/`: dev environment composition, variables, outputs, and budget.

## Workflow
1. Copy `envs/dev/terraform.tfvars.example` to `terraform.tfvars` and adjust values.
2. Run `terraform init` (configure backend and providers).
3. Review `terraform plan` to validate changes.
4. Apply with `terraform apply`.
5. Export outputs via `terraform output -json` to feed the Kubernetes deployment.

## Notes
- Modules share a tagging scheme (`Project`, `Environment`, `Owner`, `CostCenter`).
- The `iam` module is used twice: once for base roles (control plane and nodes) and once for IRSA roles.
- The budget (`aws_budgets_budget`) alerts when forecasted spend exceeds 80% or actual spend hits 100% of the configured cap.
