resource "aws_apigatewayv2_api" "http_api" {
  name          = "${local.name_prefix}-topmovies-api"
  protocol_type = "HTTP"
}


resource "aws_apigatewayv2_stage" "default" {
  api_id = aws_apigatewayv2_api.http_api.id

  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format          = "$context.requestId $context.identity.sourceIp $context.httpMethod $context.resourcePath $context.status $context.responseLatency"
  }
}

resource "aws_apigatewayv2_integration" "apigw_lambda" {
  provider = aws.ap_southeast_1  
  api_id = aws_apigatewayv2_api.http_api.id
  integration_uri = "arn:aws:apigateway:${local.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.http_api_lambda.arn}/invocations"
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Read the content of the JSON file
locals {
  route_config = jsondecode(file("${path.module}/test-event-examples/get-topmovies.json"))
  route_config2 = jsondecode(file("${path.module}/test-event-examples/get-topmovies-by-year.json"))
  route_config3 = jsondecode(file("${path.module}/test-event-examples/put-topmovies.json"))
  route_config4 = jsondecode(file("${path.module}/test-event-examples/delete-topmovies.json"))
  region = "ap-southeast-1"
}

 resource "aws_apigatewayv2_route" "get_topmovies" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = local.route_config.routeKey #refernce the route key from the json
  target    = "integrations/${aws_apigatewayv2_integration.apigw_lambda.id}" 
   # todo: fill with apporpriate value
 }


 resource "aws_apigatewayv2_route" "get_topmovies_by_year" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = local.route_config2.routeKey #refernce the route key from the json
  target    = "integrations/${aws_apigatewayv2_integration.apigw_lambda.id}" 
   # todo: fill with apporpriate value
 }

 resource "aws_apigatewayv2_route" "put_topmovies" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = local.route_config3.routeKey #refernce the route key from the json
  target    = "integrations/${aws_apigatewayv2_integration.apigw_lambda.id}" 
   # todo: fill with apporpriate value
 }

 resource "aws_apigatewayv2_route" "delete_topmovies_by_year" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = local.route_config4.routeKey #refernce the route key from the json
  target    = "integrations/${aws_apigatewayv2_integration.apigw_lambda.id}" 
   # todo: fill with apporpriate value
 }


resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.http_api_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/api-gateway/${local.name_prefix}-topmovies-api-logs"
  retention_in_days = 7
}

resource "aws_apigatewayv2_domain_name" "custom_domain" {
  depends_on = [null_resource.wait_for_cert]
  domain_name = "topmovies.sctp-sandbox.com"
  domain_name_configuration {
    certificate_arn = aws_acm_certificate.topmovies_cert.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}


resource "aws_apigatewayv2_api_mapping" "base_path_mapping" {
  api_id      = aws_apigatewayv2_api.http_api.id
  domain_name = aws_apigatewayv2_domain_name.custom_domain.domain_name
  stage       = aws_apigatewayv2_stage.default.name
}

resource "aws_acm_certificate" "topmovies_cert" {
  domain_name       = "topmovies.sctp-sandbox.com"
  validation_method = "DNS"

  tags = {
    Name = "TopMovies API Certificate"
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.topmovies_cert.domain_validation_options :
    dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.topmovies_zone.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 300
}

# Simplified wait for certificate to be issued
resource "null_resource" "wait_for_cert" {
  depends_on = [aws_route53_record.cert_validation]

  provisioner "local-exec" {
    command = <<EOT
      until [ "$(aws acm describe-certificate --certificate-arn ${aws_acm_certificate.topmovies_cert.arn} --query 'Certificate.Status' --output text)" == "ISSUED" ]; do
        echo "Waiting for certificate to be issued..."
        sleep 10
      done
      echo "Certificate issued."
    EOT
  }
}

resource "aws_route53_record" "apigateway_alias" {
  zone_id = data.aws_route53_zone.topmovies_zone.zone_id  # Correct hosted zone for your domain
  name    = "topmovies.sctp-sandbox.com"
  type    = "A"

  alias {
    #name                   = aws_apigatewayv2_domain_name.custom_domain.domain_name
    name                   = "d-70oohoirp8.execute-api.ap-southeast-1.amazonaws.com"
    zone_id                = "ZL327KTPIQFUL"  # Hosted zone ID for API Gateway (Amazon's static ID)
    evaluate_target_health = true
  }
}




