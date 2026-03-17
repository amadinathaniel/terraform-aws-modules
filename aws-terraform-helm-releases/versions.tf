terraform {
  required_version = ">= 1.14"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.36"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1.1"
    }
  }
}
