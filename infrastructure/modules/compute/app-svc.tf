resource "aws_cloudwatch_log_group" "app-svc-logs" {
  name              = "/${var.environment_val}-app-svc-logs"
}

resource "aws_ecs_task_definition" "app_svc_task_definition" {
  family             = "app-svc-task-def"
  network_mode       = "awsvpc"
  cpu                = "512"
  memory             = "1024"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn = var.ecs_task_role_arn
  task_role_arn      = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "app_svc",
      image     = "${aws_ecr_repository.app_repo.repository_url}:latest",
      cpu       = 512,
      memory    = 1024,
      essential = true,
      portMappings = [
        {
          protocol      = "tcp"
          containerPort = 3000
          hostPort      = 3000
        }
      ],
      environment = [
        {
          name  = "LOG_LEVEL"
          value = "DEBUG"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/${var.environment_val}-app-svc-logs"
          awslogs-region        = var.region
          awslogs-stream-prefix = "app-svc"
        }
      },

    }
  ])
}

resource "aws_ecs_service" "app_svc" {
  name            = "${var.environment_val}-app-svc"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_svc_task_definition.arn
  desired_count   = 0
  
  launch_type     = "FARGATE"

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 50

  network_configuration {
    assign_public_ip = false
    security_groups = [var.app_sg_id]
    subnets         = var.private_subnet_ids
  }

  load_balancer {
    target_group_arn = var.app_svc_alb_tg_arn
    container_name   = "app_svc"
    container_port   = 3000
  }

  health_check_grace_period_seconds = 60
  enable_ecs_managed_tags = false  

  tags = {
    Environment = var.environment_val
    Name        = "${var.environment_val}-app-svc"
  }

    lifecycle {
        ignore_changes = [
        tags,desired_count
        ]
    }
}