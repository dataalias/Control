terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.31.0"
    }
  }

  required_version = "~> 1.4.6"
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment                        = var.env
      Service                            = "data_hub"
      Note                               = "Managed by Terraform"
      BillingCode = "DE"
    }
  }
}

provider "archive" {}

terraform {
  backend "s3" {
    region = "us-east-1"
  }
}


resource "aws_iam_role" "lambda_role" {
  name = "${var.name == "" ? var.repo_name : var.name}LambdaFunctionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = ["apigateway.amazonaws.com","lambda.amazonaws.com","transfer.amazonaws.com"]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_for_lambda" {
  name = "${var.name == "" ? var.repo_name : var.name}TerraformRoleforLambda"
  path = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "s3:*",
          "ec2:DescribeNetworkInterfaces",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeInstances",
          "ec2:AttachNetworkInterface",
          "iam:ListRolePolicies",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:ListSecrets",
          "glue:StartWorkflowRun",
          "events:PutRule",
          "events:PutTargets",
          "events:DeleteRule",
          "events:RemoveTargets",
          "events:DisableRule",
          "events:EnableRule",
          "events:TagResource",
          "events:UntagResource",
          "events:DescribeRule",
          "events:ListTargetsByRule",
          "events:ListTagsForResource"  
        ]
        Resource = [
            "arn:aws:logs:us-east-1:${var.account_id}:log-group:/*",
            "arn:aws:s3:::${var.source_bucket_name}/*",
            "arn:aws:s3:::${var.source_bucket_name}",
            "*"
        ]
      } 
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
 role        = aws_iam_role.lambda_role.name
 policy_arn  = aws_iam_policy.iam_policy_for_lambda.arn
}

# This is the s3 trigger.
data "archive_file" "zip_the_python_code" {
type        = "zip"
source_dir  = "../${var.lambda_function_name}/"
output_path = "../${var.lambda_function_name}.zip"
}

# This is the deUtils layer (DataHub class etc).
data "archive_file" "zip_DataHub_code" {
type        = "zip"
source_dir  = "../${var.datahub_function_name}/"
output_path = "../${var.datahub_function_name}.zip"
}

resource "aws_lambda_layer_version" "python39-deutils-layer" {
  filename            = "../${var.datahub_function_name}.zip"
  layer_name          = "Python39-deUtils"
  source_code_hash    = "${filebase64sha256("../${var.datahub_function_name}.zip")}"
  compatible_runtimes = ["python3.9"]
}
/*
module: api_gateway
*/
/*
module "api_gateway" {
  source = "./modules/api_gateway"
  env = var.env
}
*/

/*
module: api_gateway
*/
/*
module "sns_topic" {
  source = "./modules/sns_topic"
  env = var.env
}
*/
/* 
sqs
*/
/*
module "sqs_queue" {
  source = "./modules/sqs"

  name                       = "deDWPostingGroup.fifo"
  dlq_name                   = "deDWPostingGroupDeadLetter.fifo"
  fifo                       = true
  max_receive_count          = 5
  visibility_timeout_seconds = 300
}
*/
/*
module: DataHub
*/


/*
module "DataHub" {
  source = "./modules/DataHub"
  env = var.env
  lambda_function_name_sch = var.lambda_function_name_sch
  iam_role_arn = "${aws_iam_role.lambda_role.arn}"
  #layers_list  = ["moneky","${var.pandas_layer}","${var.boto_layer}","${var.mssql_layer}"]
  layers_list  = ["${aws_lambda_layer_version.python39-deutils-layer.arn}","${var.pandas_layer}","${var.boto_layer}","${var.mssql_layer}"]
  subnet_ids         = var.subnet_ids # ["subnet-809a4bda"]
  security_group_ids = var.security_group_ids # ["sg-cef0c8b0","sg-0219e0118e42120c5","sg-068e4856d4a4e7811"]
  datalake_bucket          = "${var.env}-${var.datalake_bucket}"
  region                  = var.region
  db_dw                   = var.db_dw
  data_hub_connection_secret = var.secret
  
  # We want to make sure all our roles and policies are ready before creating lambdas.
  #This will not be passed down to the sub modules.
  depends_on = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
 
}
*/
/*
Generic definition for the code pipeline and the associated pipeline needed to deploy them.
*/



module "codepipeline" {
  source = "git@github.com:..."

  region                  = var.region
  account_id              = var.account_id
  artifact_bucket         = var.artifact_bucket
  artifact_prefix         = var.artifact_prefix
  artifact_encryption_key = var.artifact_encryption_key
  repo_name               = var.repo_name
  branch                  = var.branch
  parameter_store         = var.parameter_store

  unit_test_buildspec = "pipeline/buildspec_unit_test.yml"
  deploy_buildspec    = "pipeline/buildspec_deploy.yml"

  environment_variables = [
    {
      name  = "SOURCE_BUCKET_NAME"
      value = var.source_bucket_name
      type  = "PLAINTEXT"
    },
    {
      name  = "PANDAS_LAYER"
      value = var.pandas_layer
      type  = "PLAINTEXT"
    },
    {
      name  = "MSSQL_LAYER"
      value = var.mssql_layer
      type  = "PLAINTEXT"
    },
    {
      name  = "BOTO_LAYER"
      value = var.boto_layer
      type  = "PLAINTEXT"
    },
    {
      name  = "DEUTILS_LAYER"
      value = var.deutils_layer
      type  = "PLAINTEXT"
    }
  ]
}


/*
Change History

ffortunato  20230525  Adding API Gateway resources to deDataHub.
ffortunato  20230531  Adjusting Policy / Role for API Gateway to invoke Lambda.
ffortunato  20230615  Reorganizing. +seperate *.tf files for each lambda.
ffortunato  20230615  Reorganizing. +seperate *.tf files for each lambda.
ffortunato  20230626  Reorganizing. ~ lambda module.
*/