
provider "aws" {
    region = var.aws_region

default_tags {
  tags = {
    Enviroment = "dev"
    ManagedBy = "Terraform"
    Project = "EKS-Cloud-Native"
    Team = "DevOps"
  }
}
}
