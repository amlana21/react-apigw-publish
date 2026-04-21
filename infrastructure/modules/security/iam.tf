data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ecs_task_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com", "ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.environment_val}-ecs-task-role-1"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_doc.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_policy_2" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_policy_1" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

data "aws_iam_policy_document" "ecs_task_other_access" {
  statement {
    actions   = ["logs:*", "s3:*", "dynamodb:*", "cloudwatch:*", "sns:*", "lambda:*", "secretsmanager:*", "ds:*", "ec2:*", "sqs:*", "ecr:*", "ssm:*", "ecs:*","lex:*"]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecs_task_other_access" {
  name        = "${var.environment_val}-ecs-task-other-access-1"
  description = "Policy for ecs task to access other services"
  policy      = data.aws_iam_policy_document.ecs_task_other_access.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_other_access" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_other_access.arn
}