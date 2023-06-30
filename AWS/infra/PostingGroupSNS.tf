module "sns" {
  source  = "terraform-aws-modules/sns/aws"
  version = ">= 5.0"

  name = "dePostingGroupTopic.fifo"
  fifo_topic                  = true
  content_based_deduplication = true
  display_name = "PostingGroupTopic"

  topic_policy_statements = {
    sqs = {
      sid = "SQSSubscribe"
      actions = [
        "sns:Subscribe",
        "sns:Receive",
      ]

      principals = [{
        type        = "AWS"
        identifiers = ["*"]
      }]

      conditions = [{
        test     = "StringLike"
        variable = "sns:Endpoint"
        values   = [module.sqs.queue_arn]
      }]
    }
  }

  subscriptions = {
    sqs = {
      protocol = "sqs"
      endpoint = module.sqs.queue_arn
      FilterPolicyScope = "MessageAttributes"
      filter_policy = "${jsonencode({"SubscriberCode":["ODS","DL","SUBR01","SUBR02"]})}"
    }
    
  }
  /*
  tags = {
    Environment = var.env
    Department = "Data Engineering"
    DepartmentCode = "DE"
  }
  */
}

module "sqs" {
  source = "terraform-aws-modules/sqs/aws"

  name = var.sqs_pg_dw_name
  fifo_queue = true
  content_based_deduplication = true
  create_queue_policy = true

  queue_policy_statements = {
    sns = {
      sid     = "SNSPublish"
      actions = ["sqs:SendMessage"]

      principals = [
        {
          type        = "Service"
          identifiers = ["sns.amazonaws.com"]
        }
      ]

      condition = {
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values   = [module.sns.topic_arn]
      }
    }
  }
/*
  tags = {
    Environment = var.env
    Department = "Data Engineering"
    DepartmentCode = "DE"
  }
  */
}