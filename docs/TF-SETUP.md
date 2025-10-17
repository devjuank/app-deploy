# Terraform Backend Setup

## Prerequisites
- AWS CLI configured on the host (see `docs/AWS-ACCOUNT-SETUP.md` for IAM roles, policies, and profiles).
- Permissions to create S3 buckets and DynamoDB tables in the target account.
- Terraform ≥ 1.5 installed locally.

## Steps
1. **Create S3 bucket** – provision a dedicated bucket for Terraform state, e.g. `tf-state-kiusys-dev`, and enable versioning:
   ```bash
   aws s3api create-bucket --bucket tf-state-kiusys-dev --region us-east-1
   aws s3api put-bucket-versioning --bucket tf-state-kiusys-dev --versioning-configuration Status=Enabled
   ```
2. **Secure the bucket (optional but recommended)** – apply a bucket policy restricting access to your team’s principals.
3. **Create DynamoDB table** – used for state locking, e.g. `tf-state-lock-kiusys-dev` with partition key `LockID` (String):
   ```bash
   aws dynamodb create-table \
     --table-name tf-state-lock-kiusys-dev \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST
   ```
4. **Configure backend block** – in `infra/envs/dev`, add (or update) `backend.tf` or the `terraform` block in `main.tf`:
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "tf-state-kiusys-dev"
       key            = "dev/terraform.tfstate"
       region         = "us-east-1"
       dynamodb_table = "tf-state-lock-kiusys-dev"
       encrypt        = true
     }
   }
   ```
5. **Initialize backend** – run from `infra/envs/dev` with the AWS profile that assumes the Terraform role:
   ```bash
   AWS_PROFILE=terraform-dev terraform init -reconfigure
   ```
6. **Validate** – execute a dry plan to confirm state storage works:
   ```bash
   AWS_PROFILE=terraform-dev terraform plan
   ```

## Notes
- Use separate buckets/keys per environment (e.g. `dev/terraform.tfstate`, `prod/terraform.tfstate`).
- If you ever change the backend configuration, rerun `terraform init -reconfigure` to re-establish the connection.
- Consider enabling MFA delete on the S3 bucket for additional protection if compliance requires it.
