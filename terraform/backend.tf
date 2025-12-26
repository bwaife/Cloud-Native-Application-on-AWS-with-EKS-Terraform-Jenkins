terraform {
  backend "s3" {
    bucket = "cloud-native-project-terraform-state"
    region = "eu-west-1"
    encrypt = true
    use_lockfile = true 
    key = "path/to/my/terraform.tfstate"
  }
}




