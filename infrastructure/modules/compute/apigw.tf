resource "aws_apigatewayv2_vpc_link" "app_vpc_link" {
  name               = "${var.environment_val}-app-vpc-link"
  security_group_ids = [var.app_sg_id]
  subnet_ids         = var.apigw_private_subnet_ids

  tags = {
    Name        = "${var.environment_val}-app-vpc-link"
    Environment = var.environment_val
  }
}

resource "aws_apigatewayv2_api" "app_api" {
  name          = "${var.environment_val}-app-api"
  protocol_type = "HTTP"

  tags = {
    Name        = "${var.environment_val}-app-api"
    Environment = var.environment_val
  }
}

resource "aws_apigatewayv2_integration" "app_alb_integration" {
  api_id             = aws_apigatewayv2_api.app_api.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = var.app_svc_alb_listener_arn

  connection_type = "VPC_LINK"
  connection_id   = aws_apigatewayv2_vpc_link.app_vpc_link.id
}

resource "aws_apigatewayv2_route" "app_root_route" {
  api_id    = aws_apigatewayv2_api.app_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.app_alb_integration.id}"
}

resource "aws_apigatewayv2_route" "app_root_route_base" {
  api_id    = aws_apigatewayv2_api.app_api.id
  route_key = "ANY /"
  target    = "integrations/${aws_apigatewayv2_integration.app_alb_integration.id}"
}

resource "aws_apigatewayv2_stage" "app_api_stage" {
  api_id      = aws_apigatewayv2_api.app_api.id
  name        = "$default"
  auto_deploy = true

  tags = {
    Name        = "${var.environment_val}-app-api-stage"
    Environment = var.environment_val
  }
}
