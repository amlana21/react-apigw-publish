
variable environment_val {
  description = "The environment value"
  type        = string
}

variable ecs_task_role_arn {
  description = "The ARN of the ECS task role"
  type        = string
}

variable region {
  description = "The AWS region"
  type        = string
}

variable app_sg_id {
  description = "The ID of the application security group"
  type        = string
}

variable private_subnet_ids {
  description = "The IDs of the private subnets"
  type        = list(string)
}

variable app_svc_alb_tg_arn {
  description = "The ARN of the application service ALB target group"
  type        = string
}

variable app_svc_alb_listener_arn {
  description = "The ARN of the ALB listener for the app service"
  type        = string
}

variable apigw_private_subnet_ids {
  description = "Private subnet IDs filtered to AZs supported by API Gateway VPC Link"
  type        = list(string)
}
