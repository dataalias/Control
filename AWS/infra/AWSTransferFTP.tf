/******************************************************************************

AWSTransfer: deDataHubFTP

Type:     AWS Transfer Family

Description:  This is to define the Data Hub Scheduler lambda. This code block
  zips the code, creates the lambda in AWS and links several layers to
  the function. It also setsup the cron tab for firing the lambda.

******************************************************************************/
# Good sample here: https://github.com/cloudposse/terraform-aws-transfer-sftp/blob/main/main.tf

/*
resource "aws_transfer_server" "data_hub_ftp" {
  identity_provider_type = "SERVICE_MANAGED"
  protocols              = ["SFTP"]
  domain                 = var.ftp_domain
  hostname               = "transfer"
  #endpoint_type          = local.is_vpc ? "VPC" : "PUBLIC"
  #force_destroy          = var.force_destroy
  #security_policy_name   = var.security_policy_name
  #logging_role           = join("", aws_iam_role.logging[*].arn)

}

data "aws_s3_bucket" "landing" {
  # count = local.enabled ? 1 : 0
  bucket = var.source_bucket_name
}
*/


/*
Change History

ffortunato  20230621  Adding AWS Transfer Family.

*/