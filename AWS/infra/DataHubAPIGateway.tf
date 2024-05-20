/******************************************************************************
API Gateway:  deDataHubAPI

Type:         API Gateway

Description:  Allows put functionality that will apply the call's body that
conforms to the "Issue" disctionary.

******************************************************************************/

resource "aws_api_gateway_rest_api" "deDataHubAPI" {
  name = "deDataHubAPI"
  description = "This gateway brokers transactions destined for Data Hub. Update and retrevial of issue data."
  /*
  tags = {
    Environment = var.env
    Department = "Data Engineering"
    DepartmentCode = "DE"
  }
  */
}

resource "aws_api_gateway_resource" "deDataHubAPIResource" {
  parent_id   = aws_api_gateway_rest_api.deDataHubAPI.root_resource_id
  path_part   = "deDataHubAPI"
  rest_api_id = aws_api_gateway_rest_api.deDataHubAPI.id
}

resource "aws_api_gateway_method" "deDataHubAPIMethod" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.deDataHubAPIResource.id
  rest_api_id   = aws_api_gateway_rest_api.deDataHubAPI.id
}

# now point it to the lambda funtion!!!!!
resource "aws_api_gateway_integration" "deDataHubAPIIntegration" {
  http_method = aws_api_gateway_method.deDataHubAPIMethod.http_method
  resource_id = aws_api_gateway_resource.deDataHubAPIResource.id
  rest_api_id = aws_api_gateway_rest_api.deDataHubAPI.id
  integration_http_method = "POST"
  type        = "AWS_PROXY"
  uri = aws_lambda_function.terraform_deDataHubAPIHandler.invoke_arn
}

resource "aws_api_gateway_deployment" "deDataHubAPIDeployment" {
  rest_api_id = aws_api_gateway_rest_api.deDataHubAPI.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.deDataHubAPIResource.id,
      aws_api_gateway_method.deDataHubAPIMethod.id,
      aws_api_gateway_integration.deDataHubAPIIntegration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "APIGatewayStage" {
  deployment_id = aws_api_gateway_deployment.deDataHubAPIDeployment.id
  rest_api_id   = aws_api_gateway_rest_api.deDataHubAPI.id
  stage_name    = var.env
}

data "aws_iam_policy_document" "api_gateway_policy" {
  statement {
    actions = [
      "apigateway:*",
      "lambda:InvokeFunction",
      "sts:AssumeRole"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "api_gateway_policy" {
  name   = "deDataHubAPIGatewayPolicy"
  policy = data.aws_iam_policy_document.api_gateway_policy.json
}

resource "aws_iam_role_policy_attachment" "api_gateway_role_policy" {
  role       = module.codepipeline.cloud_formation_execution_role.name
  policy_arn = aws_iam_policy.api_gateway_policy.arn
}

# End API Gateway Resources

/*
Change History

ffortunato  20230525  Adding API Gateway resources to deDataHub.
ffortunato  20230531  Adjusting Policy / Role for API Gateway to invoke Lambda.
ffortunato  20230615  Reorganizing. +seperate *.tf files for each lambda.
*/