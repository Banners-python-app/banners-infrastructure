terraform {
    required_version = ">= 1.10"

    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 6.47"
      }

      helm = {
        source = "hashicorp/helm"
        version = "~> 2.0"
      }
    }

    backend "s3" {
    bucket = "tf-infra-creation"
    key = "dev/eks.tfstate"
    region = "us-east-1"
    use_lockfile = true
    encrypt = true
  }
}