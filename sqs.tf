locals {
  is_fifo = try(var.fifo_settings.enabled, false)
  has_dlq = try(var.dlq_settings.enabled, false)
}

moved {
  from = aws_sqs_queue.queue
  to   = aws_sqs_queue.this
}
resource "aws_sqs_queue" "this" {
  name                       = var.name != null ? (local.is_fifo && !endswith(var.name, ".fifo")) ? "${var.name}.fifo" : var.name : null
  name_prefix                = var.name_prefix
  visibility_timeout_seconds = var.visibility_timeout_seconds
  max_message_size           = var.max_message_size
  delay_seconds              = var.delay_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds
  message_retention_seconds  = var.message_retention_seconds
  policy                     = var.policy
  tags                       = var.tags

  # Using the SQS account-bound key is secure enough
  #tfsec:ignore:aws-sqs-queue-encryption-use-cmk
  kms_master_key_id                 = var.kms_master_key_id
  kms_data_key_reuse_period_seconds = var.kms_data_key_reuse_period_seconds

  # FIFO settings
  fifo_queue                  = local.is_fifo
  fifo_throughput_limit       = local.is_fifo ? var.fifo_settings.throughput_limit : null
  content_based_deduplication = local.is_fifo ? var.fifo_settings.content_based_deduplication : null
  deduplication_scope         = local.is_fifo ? var.fifo_settings.deduplication_scope : null

  lifecycle {
    precondition {
      condition     = var.name != null || var.name_prefix != null
      error_message = "Either name or name_prefix must be provided"
    }

    precondition {
      condition     = var.name == null || var.name_prefix == null
      error_message = "Either name or name_prefix must be provided, not both"
    }

    precondition {
      condition     = var.kms_master_key_id != null
      error_message = "Queue must be encrypted using KMS"
    }
  }
}

# DLQ settings
resource "aws_sqs_queue_redrive_policy" "this" {
  count     = local.has_dlq ? 1 : 0
  queue_url = aws_sqs_queue.this.url
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[count.index].arn
    maxReceiveCount     = var.dlq_settings.max_receive_count
  })
}
resource "aws_sqs_queue_redrive_allow_policy" "this" {
  queue_url = aws_sqs_queue.this.url
  # Don't allow the primary queue to redrive into another queue
  redrive_allow_policy = jsonencode({
    redrivePermission = "denyAll"
  })
}


moved {
  from = aws_sqs_queue.dlq
  to   = aws_sqs_queue.dlq[0]
}
resource "aws_sqs_queue" "dlq" {
  count = local.has_dlq ? 1 : 0

  name                       = var.name != null ? "${var.name}${var.dlq_settings.suffix}" : null
  name_prefix                = var.name_prefix != null ? "${var.name_prefix}${var.dlq_settings.suffix}" : null
  visibility_timeout_seconds = var.dlq_settings.visibility_timeout_seconds
  max_message_size           = var.max_message_size
  delay_seconds              = var.dlq_settings.delay_seconds
  receive_wait_time_seconds  = var.dlq_settings.receive_wait_time_seconds
  message_retention_seconds  = var.dlq_settings.message_retention_seconds != null ? var.dlq_settings.message_retention_seconds : var.message_retention_seconds
  policy                     = var.dlq_settings.policy != null ? var.dlq_settings.policy : var.policy
  tags                       = var.tags

  # Using the SQS account-bound key is secure enough
  #tfsec:ignore:aws-sqs-queue-encryption-use-cmk
  kms_master_key_id                 = var.kms_master_key_id
  kms_data_key_reuse_period_seconds = var.kms_data_key_reuse_period_seconds

  # FIFO settings
  fifo_queue                  = local.is_fifo
  fifo_throughput_limit       = local.is_fifo ? var.fifo_settings.throughput_limit : null
  content_based_deduplication = local.is_fifo ? var.fifo_settings.content_based_deduplication : null
  deduplication_scope         = local.is_fifo ? var.fifo_settings.deduplication_scope : null
}
resource "aws_sqs_queue_redrive_allow_policy" "dlq" {
  count     = local.has_dlq ? 1 : 0
  queue_url = aws_sqs_queue.dlq[0].url

  # Redrive only works for non-fifo queues
  redrive_allow_policy = var.dlq_settings.redrive_enabled ? jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.this.arn]
    }) : jsonencode({
    redrivePermission = "denyAll"
  })
}

