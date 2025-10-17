terraform {
  backend "s3" {
    bucket         = "tf-state-kiusys-dev"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-state-lock-kiusys-dev"
    encrypt        = true
  }
}