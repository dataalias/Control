/******************************************************************************

Function: deDataHubAPIHandler

Type:     Lambda

Description:  This is to define the Data Hub API lambda. This code block
  zips the code, creates the lambda in AWS and links several layers to
  the function.

******************************************************************************/
# Creating zip archive.
data "archive_file" "zip_DataHubAPIHandler_code" {
type        = "zip"
source_dir  = "../${var.lambda_function_name_api}/"
output_path = "../${var.lambda_function_name_api}.zip"
}

# defining resource
resource "aws_lambda_function" "terraform_deDataHubAPIHandler" {
  filename                       = "../${var.lambda_function_name_api}.zip"
  function_name                  = var.lambda_function_name_api
  description                    = "This function supports API Gateway Calls to modify datahub data."   
  role                           = aws_iam_role.lambda_role.arn
  handler                        = "app.lambda_handler"
  runtime                        = "python3.9"
  depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
  source_code_hash               = data.archive_file.zip_DataHubAPIHandler_code.output_base64sha256
  layers                         = ["${aws_lambda_layer_version.python39-dedatahub-layer.arn}",var.mssql_layer,var.boto_layer]
  timeout                        = 120
  environment {
   variables = {
      MyLambdaEnvName =  var.env,
      Secrets         =  var.secret
    }
  }
  vpc_config {
       subnet_ids = var.subnet_ids
       security_group_ids = var.security_group_ids
   }
/*
   tags = {
    Environment = var.env
    Department = "Data Engineering"
    DepartmentCode = "DE"
  }
  */
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_deDataHubAPIHandler.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  #source_arn = "${aws_api_gateway_rest_api.deDataHubAPI.execution_arn}/*/*/*"
  source_arn = "${aws_api_gateway_rest_api.deDataHubAPI.execution_arn}/${var.env}/POST/${var.api_method_post_issue}"
}

resource "aws_lambda_function_event_invoke_config" "lambdaconfig_deDataHubAPIHandler" {
  function_name                = aws_lambda_function.terraform_deDataHubAPIHandler.function_name
  maximum_event_age_in_seconds = 120
  maximum_retry_attempts       = 0
}

# end of lambda API definition
