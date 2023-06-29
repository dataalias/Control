/*
module "eventbridge" {
  source = "terraform-aws-modules/eventbridge/aws"

  bus_name = "dePostingGroupBus"

  rules = {
    posting_group = {
      description   = "Capture all posting group notifiations."
      event_pattern = jsonencode({ "source" : ["payload"] })
      enabled       = true
    }
  }
*/
/*
  targets = {
    posting_group = [
      {
        name            = "send-posting-group-to-sqs"
        arn             = aws_sqs_queue.posting_group_queue.arn
        dead_letter_arn = aws_sqs_queue.posting_group_deadletter_queue.arn
      },
      {
        name = "log-posting-group-to-cloudwatch"
        arn  = aws_cloudwatch_log_group.this.arn
      }
    ]
  }
*/
/*
  tags = {
    Environment = var.env
    Department = "Data Engineering"
    DepartmentCode = "DE"
  }
}

resource "aws_sqs_queue" "posting_group_queue" {
  name       = var.sqs_pg_dw_name
  fifo_queue = var.fifo
  content_based_deduplication = true
    
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.posting_group_deadletter_queue.arn
    maxReceiveCount     = var.max_receive_count
  })
  visibility_timeout_seconds = var.timeout_seconds
}

resource "aws_sqs_queue" "posting_group_deadletter_queue" {
  name       = var.sqs_pg_dlq_name
  fifo_queue = var.fifo
}
*/