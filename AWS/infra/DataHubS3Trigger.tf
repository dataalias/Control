/******************************************************************************

Function: deDataHubS3Trigger

Type:     lambda
          CloudWatch - S3 Event

Description:  This is to define the Data Hub API lambda. This code block
  zips the code, creates the lambda in AWS and links several layers to
  the function.

******************************************************************************/

resource "aws_lambda_function" "terraform_DataHubS3Trigger" {
  filename                       = "../${var.lambda_function_name}.zip"
  description                    = "This function watches for new files within the data lake and initiates glue proceses accordingly."
  function_name                  = var.lambda_function_name
  role                           = aws_iam_role.lambda_role.arn
  handler                        = "app.lambda_handler"
  runtime                        = "python3.9"
  depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
  source_code_hash               = data.archive_file.zip_the_python_code.output_base64sha256
  #layers                         = ["${aws_lambda_layer_version.python39-deutils-layer.arn}","arn:aws:lambda:us-east-1:760872459209:layer:pandas39:1","arn:aws:lambda:us-east-1:760872459209:layer:boto39:1","arn:aws:lambda:us-east-1:760872459209:layer:pymssql39:1"]
  layers                         = ["${aws_lambda_layer_version.python39-deutils-layer.arn}",var.pandas_layer,var.mssql_layer,var.boto_layer]
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
}


resource "aws_lambda_function_event_invoke_config" "lambdaconfig" {
  function_name                = aws_lambda_function.terraform_DataHubS3Trigger.function_name
  maximum_event_age_in_seconds = 120
  maximum_retry_attempts       = 0
}

# defining hte cloud watch trigger.
resource "aws_s3_bucket_notification" "aws-lambda-trigger" {
  bucket = "${var.source_bucket_name}"
  lambda_function {
    lambda_function_arn = "${aws_lambda_function.terraform_DataHubS3Trigger.arn}"
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "RawData/"
    #filter_prefix       = "Conformed/"  # Shouldn't this be RawData ??
  }
}

resource "aws_lambda_permission" "S3trigger" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.terraform_DataHubS3Trigger.function_name}"
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.source_bucket_name}"
}
