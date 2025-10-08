# AWS Account Preparation

Use this checklist before running the main Terraform stack.

## 1. Credentials & Profiles
1. **Create infrastructure policy** – Use `docs/dev-role-policy.json` as the body for a customer managed policy (e.g. `TerraformDevPolicy`).
2. **Create assume-role policy** – Create another customer managed policy (e.g. `AllowAssumeTerraformRole`) with:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "arn:aws:iam::<account-id>:role/TerraformDevRole"
    }
  ]
}
```
3. **Create assume-role policy** – create a second policy (e.g. `AllowAssumeTerraformRole`) granting `sts:AssumeRole` on `TerraformDevRole`.
4. **Create IAM user** – if AWS SSO is unavailable, create `terraform-dev-user` (or similar) and attach `AllowAssumeTerraformRole`. Enable MFA if possible.
5. **Obtain credentials** – retrieve the access key ID/secret for the user.
6. **Configure host credentials** – store them via `aws configure --profile terraform-dev-user` or by editing `~/.aws/credentials` under `[terraform-dev-user]`.
7. **Configure assumed-role profile** – add to `~/.aws/config`:

   ```
   [profile terraform-dev]
   source_profile = terraform-dev-user
   role_arn = arn:aws:iam::<account-id>:role/TerraformDevRole
   region = us-east-1
   ```

8. **Verify profiles** –
   - `aws sts get-caller-identity --profile terraform-dev-user`
   - `aws sts get-caller-identity --profile terraform-dev`

9. **Terraform smoke test** – run `terraform init` and `terraform plan` from `infra/envs/dev` using `AWS_PROFILE=terraform-dev`.
