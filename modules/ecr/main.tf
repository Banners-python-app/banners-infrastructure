resource "aws_ecr_repository" "this" {
    name = var.repository_name
    image_tag_mutability = "IMMUTABLE"

    image_scanning_configuration {
      scan_on_push = true       # automatically scan images for vulrelabilities
    }   

    encryption_configuration {
      encryption_type = "KMS"   # encrypt at rest
    }   

    tags = var.tags
}

# lifecycle policies: keeps production clean and manages cloud costs
resource "aws_ecr_lifecycle_policy" "this" {
    repository = aws_ecr_repository.this.name

    policy = jsonencode({
        rules = [
            {
                rulePriority = 1            # for rollbacks safety net rule
                description = "Keep last 2 tagged images for rollback capability"
                selection = {               # criteria used to find the images
                    tagStatus = "tagged"    # ECR to look for tagged images
                    tagPrefixList = ["v","release"]        # filters images tagged with version "v1.0.0" or "release"
                    countType = "imageCountMoreThan"       # triggers cleanup once images goes over a specific value
                    countNumber = 2         # if we pushed 3rd image then 1st will be flagged for removal
                }
                action = {
                    type = "expire"         # delete permenantly
                }
            },
            {
                rulePriority = 2            # cleaning up feature branch & untagged images
                description = "Expire temporary feature branch / untagged images after 3 days"
                selection = {
                    tagStatus = "untagged"
                    countType = "sinceImagePushed"
                    countUnit = "days"
                    countNumber = 3
                }
                action = {
                    type = "expire"
                }
            }
        ]
    })
}

