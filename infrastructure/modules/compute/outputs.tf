

# out for api gateway url
output "api_gateway_url" {
  value = aws_apigatewayv2_stage.app_api_stage.invoke_url
}