
resource "aws_ecr_repository" "ecr_app" {
    name = "my-app"
    image_tag_mutability = "MUTABLE"
    image_scanning_configuration {
        scan_on_push = true
    }
}

resource "aws_ecr_lifecycle_policy" "ecr_app" {
    repository = aws_ecr_repository.ecr_app.name
    
    policy = jsonencode({
        rules = [
            {
                rulePriority = 1
                description = "Keep last 10 tagged images "
                selection = {
                    tagStatus = "tagged"
                    tagPrefixList = ["prod-"]
                    countType = "imageCountMoreThan"
                    countNumber = 10
                }
                action = {
                    type = "expire"
                }
            }, 
            {
                rulePriority = 2
                description  = "Delete untagged images after 7 days"
                selection = {
                    tagStatus = "untagged"
                    countType = "sinceImagePushed"
                    countUnit = "days"
                    countNumber = 7
                }
                action = {
                    type = "expire"
                }
            }
        ]
    })
  
}





