output "queue" {
  value = aws_sqs_queue.this
}

output "dlq" {
  value = local.has_dlq ? aws_sqs_queue.dlq[0] : null
}

output "policies" {
  value = {
    publish       = data.aws_iam_policy_document.publish
    subscribe     = data.aws_iam_policy_document.subscribe
    subscribe_dlq = local.has_dlq ? data.aws_iam_policy_document.subscribe_dlq[0] : null
  }
}
