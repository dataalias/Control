
output "deDataHubAPIHandler_lambda_arn" {
  value = aws_lambda_function.terraform_deDataHubAPIHandler.arn
}

output "deDataHubScheduler_lambda_arn" {
  value = aws_lambda_function.terraform_DataHubScheduler.arn
}

output "deDataHubS3Trigger_lambda_arn" {
  value = aws_lambda_function.terraform_DataHubS3Trigger.arn
}

output "deDataHubScheduleName"{
  value = aws_cloudwatch_event_rule.schedule.name
}

output "deDataHubAPIGatewayName"{
  value = aws_api_gateway_rest_api.deDataHubAPI.name
}
/*
output "PostingGroupTopicarn"{
  value = module.sns.topic_arn # aws_sqs_queue.posting_group_queue_dw.arn
}
output "PostingGroupSQSarn"{
value = module.sqs.queue_arn # aws_sqs_queue.posting_group_deadletter_queue.arn
}
*/
output "SchedulerLayers"{
value = aws_lambda_function.terraform_DataHubScheduler.layers # aws_sqs_queue.posting_group_deadletter_queue.arn
}
/*
output "PostingGroupSQSarn"{
  value = aws_sqs_queue.posting_group_queue_dw.arn
}
output "PostingGroupSQSDLQarn"{
value = aws_sqs_queue.posting_group_deadletter_queue.arn
}
*/
