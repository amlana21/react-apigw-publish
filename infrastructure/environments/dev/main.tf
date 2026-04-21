module "networking" {
  source              = "../../modules/networking"
  vpc_name            = local.vpc_name
  app_gateway_name    = local.app_gateway_name
    environment_val      = local.environment
}


module "security" {
  source              = "../../modules/security"
  environment_val      = local.environment
}

module "compute" {
  source                    = "../../modules/compute"
  environment_val           = local.environment
  ecs_task_role_arn         = module.security.ecs_task_role_arn
  region                    = local.region
  app_sg_id                 = module.networking.app_sg_id
  private_subnet_ids        = module.networking.private_subnet_ids
  apigw_private_subnet_ids  = module.networking.apigw_private_subnet_ids
  app_svc_alb_tg_arn        = module.networking.app_svc_lb_tg_arn
  app_svc_alb_listener_arn  = module.networking.app_svc_alb_listener_arn
}