terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32.0"
    }
  }
  #after the first initializtion i initilized remote backend in s3 bucket to ensure resilience of the state file 
  /*
  backend "s3" {
    bucket = "terraform-backend-bucket-kohi-tfstate"
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }
  */
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

provider "aws" {
  region = "eu-north-1"
  # setting default tag to all the configuration at once. .
  default_tags {
    tags = {
      Environment = "test"
      type        = "terraform"
    }
  }
}



