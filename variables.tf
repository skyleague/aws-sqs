variable "name" {
  description = "Name of the queue (cannot be combined with name_prefix)."
  type        = string
  default     = null
}

variable "name_prefix" {
  description = "Name prefix for the queue (cannot be combined with name)."
  type        = string
  default     = null
}

variable "visibility_timeout_seconds" {
  description = "Delay before messages received (using ReceiveMessage, e.g. Lambda subscription) become visible again."
  type        = number
  default     = 30
}

variable "max_message_size" {
  description = "Maximum message size (don't provide this, unless you have a real use-case to restrict this)."
  type        = number
  default     = null
}

variable "delay_seconds" {
  description = "Delay before messages sent into the queue become visible."
  type        = number
  default     = null
}

variable "receive_wait_time_seconds" {
  description = "Wait time before returning empty receives. This can be used to configure queue-level long polling."
  type        = number
  default     = null
}

variable "policy" {
  description = "Resource policy for the SQS queue."
  type        = string
  default     = null
}

variable "kms_master_key_id" {
  description = "KMS key to encrypt messages with."
  type        = string
  default     = "alias/aws/sqs"
}

variable "kms_data_key_reuse_period_seconds" {
  description = "Length of time for SQS to reuse the KMS data key. Higher settings will reduce the amount of KMS API calls."
  type        = number
  default     = null
}

variable "tags" {
  description = "Tags to put on the queue (besides the provider level default_tags)."
  type        = map(string)
  default     = null
}

variable "fifo_settings" {
  description = "Settings to setup this queue as a FIFO queue. If enabled, the queue is by default set up as a high-throughput FIFO."
  type = object({
    enabled                     = bool
    content_based_deduplication = optional(bool, true)
    deduplication_scope         = optional(string, "messageGroup")
    throughput_limit            = optional(string, "perMessageGroup")
  })
  default = null
}

variable "dlq_settings" {
  description = "Settings related to the DLQ. If the queue is configured as FIFO, then redrive from the AWS Console will NOT be enabled."
  type = object({
    enabled           = bool
    suffix            = optional(string, "-dlq")
    max_receive_count = optional(number, 5)
    redrive_enabled   = optional(bool, true)

    visibility_timeout_seconds = optional(number)
    delay_seconds              = optional(number)
    receive_wait_time_seconds  = optional(number)
    policy                     = optional(string)
  })
  default = {
    enabled = true
  }
}
