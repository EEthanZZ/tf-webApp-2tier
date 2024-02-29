terraform {
  backend "s3" {
    key = "terraform/tfstate.tfstate"
    bucket = "ethan-tf-backend"
    region = "us-east-2"
  }
}
