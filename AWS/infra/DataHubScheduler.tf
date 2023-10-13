/******************************************************************************

Function: deDataHubScheduler

Type:     Lambda,
          CloudWatch - Scehduled Event

Description:  This is to define the Data Hub Scheduler lambda. This code block
  zips the code, creates the lambda in AWS and links several layers to
  the function. It also setsup the cron tab for firing the lambda.

******************************************************************************/

# Zip up the app.py for deploy to the Lambda DataHubScheduler
data "archive_file" "zip_DataHubScheduler" {
    type        = "zip"
    source_dir  = "../${var.lambda_function_name_sch}/"
    output_path = "../${var.lambda_function_name_sch}.zip"
}

resource "aws_lambda_function" "terraform_DataHubScheduler" {
  filename                       = "../${var.lambda_function_name_sch}.zip"
  function_name                  = var.lambda_function_name_sch
  description                    = "This function allows DataHub to schedule feed imports or exports."
  role                           = aws_iam_role.lambda_role.arn
  handler                        = "app.lambda_handler"
  runtime                        = "python3.9"
  depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
  source_code_hash               = data.archive_file.zip_DataHubScheduler.output_base64sha256
  layers                         = ["${aws_lambda_layer_version.python39-dedatahub-layer.arn}",var.mssql_layer,var.boto_layer]
  timeout                        = 240
  
  environment {
   variables = {
      MyLambdaEnvName         = var.env,
      DataHubConnectionSecret = var.secret,
      TriggerTypeCode         = "SCH",
      DatalakeBucket          = "${var.env}-${var.datalake_bucket}",
      Region                  = var.region,
      db_dw                   = var.db_dw
    }
  }

  vpc_config {
       subnet_ids = var.subnet_ids
       security_group_ids = var.security_group_ids
   }
}

resource "aws_lambda_function_event_invoke_config" "deDataHubScheduler_config" {
  function_name                = aws_lambda_function.terraform_DataHubScheduler.function_name
  maximum_event_age_in_seconds = 120
  maximum_retry_attempts       = 0
}

# Now we schedule it.

# The actual schedule. This will invoke the Lambda function every 10 min on all weekdays. 
# You can see more examples of cron expressions here:
# https://docs.aws.amazon.com/lambda/latest/dg/services-cloudwatchevents-expressions.html

resource "aws_cloudwatch_event_rule" "schedule" {
    name = "deDataHubSchedule"
    description = "Schedule for DataHub Scheduler Lambda Function. This process runs every 10 minutes 24x7."
    schedule_expression = var.schedule_DataHub # var.schedule
}

resource "aws_cloudwatch_event_target" "schedule_DataHubScheduler" {
    rule = aws_cloudwatch_event_rule.schedule.name
    target_id = "processing_lambda"
    arn = aws_lambda_function.terraform_DataHubScheduler.arn
}

resource "aws_lambda_permission" "allow_events_bridge_to_run_lambda" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.terraform_DataHubScheduler.function_name
    principal = "events.amazonaws.com"
}
