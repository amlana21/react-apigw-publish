

resource "aws_ecs_cluster" "app_cluster" {
  name = "${var.environment_val}-app-cluster"
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}