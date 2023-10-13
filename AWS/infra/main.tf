terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.31.0"
    }
  }

  required_version = "~> 1.5.0"
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment                        = var.env
      Service                            = "data_hub"
      Note                               = "Managed by Terraform"
      "mission:managed-cloud:monitoring" = "infrastructure"
      Department                         = "Data Engineering"
      DepartmentCode                     = "DE"
      Repository                         = var.artifact_prefix
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


# Next three resources are for the stupid key on the assets bucket...
# TODO: Remove this when we can by moving to the v2 assets bucket. This bucket doesn't have the custom keys.
/*
data "aws_iam_policy_document" "update_kms_service_policy" {
  statement {
    sid= "AllowUseOfKMSKey"
    effect= "Allow"
    actions= [
        "kms:*"
    ]
    resources= ["arn:aws:kms:us-east-1:0000000000:key/51981c0d-892e-4148-f8f-3d2d6b09bae"
    ,"arn:aws:kms:us-east-1:0000000000:key/eca20459-4116-467-8fdc-4dd9ba166c6"]
  }
}

resource "aws_iam_policy" "update_kms_service_policy" {
  name   = "${var.artifact_prefix}_KMS_Bridge_UpdateServicePolicy"
  policy = data.aws_iam_policy_document.update_kms_service_policy.json
}

# Allow the build pipeline to talk to our s3 bucket.
resource "aws_iam_role_policy_attachment" "update_kms_service_role_policy" {
  role       = module.codepipeline.pipeline_execution_role.name
  policy_arn = aws_iam_policy.update_kms_service_policy.arn
}
# Allow test block to decrypt.
resource "aws_iam_role_policy_attachment" "update_kms_for_cloud_formation_role_policy" {
  role       = module.codepipeline.cloud_formation_execution_role.name
  policy_arn = aws_iam_policy.update_kms_service_policy.arn
}
*/

# This is the s3 trigger. lambda_function_name     = "DataHubS3Trigger"
data "archive_file" "zip_the_python_code" {
type        = "zip"
source_dir  = "../${var.lambda_function_name}/"
output_path = "../${var.lambda_function_name}.zip"
}

/*
# Copies the myapp.conf file to /etc/myapp.conf
provisioner "file" {
  source      = "../${var.datahub_function_name}/src/"
  destination = "../${var.datahub_function_name}/python/"
}
*/
# This is the deUtils layer (DataHub class etc). datahub_function_name    = "src_dh_layer"
data "archive_file" "zip_DataHub_code" {
type        = "zip"
source_dir  = "../${var.datahub_function_name}/"
output_path = "../${var.datahub_function_name}.zip"
}

#ToDo make the layer and all references deUtils not de datahub ...
# check to see if the hash of the file has changed. If so load it up. We are going to rebuild the zip in the build spec yaml. becuase we need to change the folder strucutre.

resource "aws_lambda_layer_version" "python39-dedatahub-layer" {
  filename            = "../${var.datahub_function_name}.zip"
  layer_name          = "Python39-deDataHub"
  source_code_hash    = "${filebase64sha256("../${var.datahub_function_name}.zip")}"
  compatible_runtimes = ["python3.9"]
}

/*
resource "aws_lambda_layer_version" "python39-deutils-layer" {
  filename            = "../${var.datahub_function_name}.zip"
  layer_name          = "Python39-deUtils"
  source_code_hash    = "${filebase64sha256("../${var.datahub_function_name}.zip")}"
  compatible_runtimes = ["python3.9"]
}
*/
/*
Generic definition for the code pipeline and the associated pipeline needed to deploy them.
*/

module "codepipeline" {
  source = "git@github.com:MyProject/terraform-codepipeline.git?ref=2d8000255c23a8b83ee927acf1007f8e477198ea"
  region                  = var.region
  account_id              = var.account_id
  artifact_bucket         = var.artifact_bucket
  artifact_prefix         = var.artifact_prefix
  artifact_encryption_key = var.artifact_encryption_key
  repo_name               = var.repo_name
  branch                  = var.branch
  parameter_store         = var.parameter_store
  
  stages = [
    {
      stage_name = "Test"
      actions = [
        {
          project_name          = "${var.repo_name}_Test"
          buildspec             = "pipeline/buildspec_unit_test.yml"
          environment_variables = []
        }
      ]
    },
    {
      stage_name = "Deploy"
      # Stages can have multiple actions which will run in parallel
      actions = [
        {
          project_name          = var.repo_name
          buildspec             = "pipeline/buildspec_deploy.yml"
          environment_variables = [
            {
              name  = "ENV"
              value = var.env
              type  = "PLAINTEXT"
            },
            {
              name  = "SOURCE_BUCKET_NAME"
              value = var.source_bucket_name
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
              name  = "DATAHUB_LAYER"
              value = var.datahub_layer
              type  = "PLAINTEXT"
            }
          ]
        }
      ]
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