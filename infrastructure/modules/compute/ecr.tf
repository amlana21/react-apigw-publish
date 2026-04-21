resource "aws_ecr_repository" "app_repo" {
  
  name                 = "${var.environment_val}-app-repo"
  force_delete         = true
}