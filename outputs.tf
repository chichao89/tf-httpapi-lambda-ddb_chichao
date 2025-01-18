output "invoke_url" {
  value = trimsuffix(aws_apigatewayv2_stage.default.invoke_url, "/")
}

# Fetch the Regional Domain Name of the API Gateway
output "api_gateway_regional_domain_name" {
  value = aws_apigatewayv2_domain_name.custom_domain.domain_name
}

