data "aws_iam_policy_document" "publish" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
    ]
    resources = [aws_sqs_queue.this.arn]
  }

  # https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-key-management.html
  dynamic "statement" {
    for_each = var.kms_master_key_id != null && var.kms_master_key_id != "alias/aws/sqs" ? [var.kms_master_key_id] : []
    content {
      effect = "Allow"
      actions = [
        "kms:GenerateDataKey",
        "kms:Decrypt",
      ]
      resources = [var.kms_master_key_id]
    }
  }
}

data "aws_iam_policy_document" "subscribe" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ChangeMessageVisibility",
    ]
    resources = [aws_sqs_queue.this.arn]
  }

  # https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-key-management.html
  dynamic "statement" {
    for_each = var.kms_master_key_id != null && var.kms_master_key_id != "alias/aws/sqs" ? [var.kms_master_key_id] : []
    content {
      effect = "Allow"
      actions = [
        "kms:Decrypt",
      ]
      resources = [var.kms_master_key_id]
    }
  }
}

data "aws_iam_policy_document" "subscribe_dlq" {
  count = local.has_dlq ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ChangeMessageVisibility",
    ]
    resources = [aws_sqs_queue.dlq[count.index].arn]
  }

  # https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-key-management.html
  dynamic "statement" {
    for_each = var.kms_master_key_id != null && var.kms_master_key_id != "alias/aws/sqs" ? [var.kms_master_key_id] : []
    content {
      effect = "Allow"
      actions = [
        "kms:Decrypt",
      ]
      resources = [var.kms_master_key_id]
    }
  }
}
