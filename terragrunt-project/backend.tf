# Generated by Terragrunt. Sig: nIlQXj57tbuaRZEa
terraform {
  backend "s3" {
    bucket         = "terragrunt-demo-example"
    dynamodb_table = "terragrunt-demo-example"
    encrypt        = true
    key            = "./terraform.tfstate"
    region         = "us-west-2"
  }
}
