terraform {
  backend "s3" {
    bucket         = "terragrunt-demo-example"
    key            = "<%= expansion(':ENV/:MOD_NAME/terraform.tfstate') %>"
    region         = "<%= expansion(':REGION') %>"
    encrypt        = true
    dynamodb_table = "terragrunt-demo-example"
  }
}
