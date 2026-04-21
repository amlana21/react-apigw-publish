locals {
  environment  = "dev"
  project_code = "apigw"
  region       = "us-east-1"
  vpc_name     = "${local.project_code}-${local.environment}-vpc"
  app_gateway_name = "${local.project_code}-${local.environment}-app-gateway"



}