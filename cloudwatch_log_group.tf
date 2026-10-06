# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# One log group per log sent to CloudWatch Logs, keyed by the log's name, so adding or
# removing one leaves the others and their logs alone.
resource "aws_cloudwatch_log_group" "this" {
  for_each = local.cloudwatch_log_groups

  region            = var.region
  name              = "/aws/redshift/cluster/${var.name}/${each.key}"
  retention_in_days = var.logging.retention_in_days
  kms_key_id        = var.logging.kms_key_id

  tags = local.tags
}
