terraform {
  backend "s3" {
    bucket = "my-terraform-state-bucket"
    region = "eu-west-1"
    encrypt = true
    dynamodb_table = "terraform-lock-table"
    key = "path/to/my/terraform.tfstate"
  }

  required_version = ">= 1.5.0"

  required_providers {
    aws = {
        source = "hashicorp/aws"
        veesion = "=> 5.31.0"
    }
    
    kubernetes = {
        source = "hashicorp/kubernetes"
        version = "=> 2.24.0"
    }
  }

}

provider "aws" {
    region = "eu-west-1"

    default_tags {
        tags = {
            Environment = "dev"
            ManagedBy  = "Terraform"
            Project = "cloud-native-eks-project"
            Team = "DevOps"
        }
    }
}



