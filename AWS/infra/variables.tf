variable "env" {
  description = "The environment being deployed."
  type        = string
  validation {
    condition     = var.env == "dev" || var.env == "prod"
    error_message = "The env value must be dev or prod."
  }
}
variable "region" {
  description = "The AWS region."
  type        = string
  default     = "us-east-1"
}

variable "db_dw" {
  description = "Data Warehosue database server name."
  type        = string
}

variable "db_dh" {
  description = "Data Hub database server name."
  type        = string
}

variable "account_id" {
  description = "The AWS account ID."
  type        = string
}

variable "dev_account_id" {
  description = "The development AWS account ID."
  type        = string
  default     = null
}

variable "datalake_bucket" {
  description = "The S3 bucket Data Lake."
  type        = string
}

variable "artifact_bucket" {
  description = "The S3 bucket name where build artifacts are stored."
  type        = string
}

variable "artifact_prefix" {
  description = "The folder to put the artifact in inside of the S3 bucket."
  type        = string
}
/*
variable "artifact_prefix_api" {
  description = "The folder to put the artifact in inside of the S3 bucket for the API lambda."
  type        = string
}
*/
variable "artifact_encryption_key" {
  description = "The ARN of the KMS key used to encrypt artifacts put into the artifact S3 bucket."
  type        = string
}

variable "repo_name" {
  description = "The name of the CodeCommit / GitHub repo that triggers the CodePipeline."
  type        = string
  default     = "deDataHub"
}

# removing bacuase git hub doesn't have arns. Should we add a link to git hub?
variable "repo_arn" {
  description = "The ARN of the CodeCommit repo that triggers the CodePipeline."
  type        = string
  default = "value"
}

variable "branch" {
  description = "The name of the CodeCommit repo branch that triggers the CodePipeline."
  type        = string
}

variable "prod_branch" {
  description = "The name of the CodeCommit / GitHub repo branch that triggers the production CodePipeline."
  type        = string
  default     = "main"
}

variable "prod_event_bus" {
  description = "The ARN of the default EventBridge event bus on the production AWS account."
  type        = string
  default     = "arn:aws:events:us-east-1:582033825934:event-bus/default"
}

variable "code_commit_access_role_arn" {
  description = "The IAM role that gives the production account access to CodeCommit in the development account."
  type        = string
  default     = null
}

variable "secret" {
  description = "Name of the ParameterStore key."
  type        = string
}

variable "parameter_store" {
  description = "Name of the ParameterStore key."
  type        = string
}

variable "source_bucket_name" {
  description = "The S3 bucket that will trigger the Lambda function."
  type        = string
}

variable "lambda_function_name" {
  description = "The name of the Lambda function."
  type        = string
}

variable "lambda_function_name_sch" {
  description = "The name of the Lambda function for deDataHubScheduler."
  type        = string
}

variable "lambda_function_name_api" {
  description = "The name of the Lambda function for deDataHubAPIHandler."
  type        = string
}

variable "datahub_function_name" {
  description = "The name of the Lambda function."
  type        = string
}

variable "pandas_layer" {
  type = string
}

variable "mssql_layer" {
  type = string
}

variable "boto_layer" {
  type = string
}

variable "deutils_layer" {
  type = string
}

variable "name" {
  description = "The name of the CodePipeline."
  type        = string
  default     = ""
}

variable "timeout_seconds" {
  description = "The number of seconds before the application times out."
  type        = number
  default     = 120
}
/*
module "schedule_DataHub" {
  source = "../_modules/.."
  config = module.config
  schedule = "cron(0/10 * ? * MON-SUN *)"
}
*/
variable "schedule_DataHub" {
  description =" Chron tab expression for run schedule."
  type      = string
  default = "cron(0/10 * ? * MON-SUN *)"
}

#SQS Variables
variable "sqs_pg_dw_name" {
  description = "The name of the SQS queue."
  type        = string
}

variable "sqs_pg_dlq_name" {
  description = "The name of the dead-letter queue."
  type        = string
}

variable "fifo" {
  description = "Is the queue a FIFO queue."
  type        = bool
  default     = false
}

variable "max_receive_count" {
  description = "The number of times a message is delivered to the source queue before being moved to the dead-letter queue."
  type        = number
  default     = 10
}
# End SQS

#AWS Transfer
variable "ftp_domain" {
  description = "This is the URL / doin for the ftp site eternal facing."
  type        = string
  default     = "transfer.ascentfunding.com"
}
/*
variable "iam_role_arn" {
  type    = string
  default ="N/A"
}
*/

variable "data_hub_connection_secret" {
  type    = string
}

variable "subnet_ids" {
  type    = list(string)
  default = ["subnet--#######"]
}

variable "security_group_ids" {
  type    = list(string)
  default = ["sg-#######"]
}

variable "layers_list" {
  type    = list(string)

}
