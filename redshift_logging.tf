# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_redshift_logging" "this" {
  count = var.logging.destination != null ? 1 : 0

  region               = var.region
  cluster_identifier   = aws_redshift_cluster.this.id
  log_destination_type = var.logging.destination
  # AWS accepts a list of logs only for CloudWatch Logs; S3 gets all that are on.
  log_exports   = var.logging.destination == "cloudwatch" ? sort(tolist(var.logging.log_exports)) : null
  bucket_name   = var.logging.destination == "s3" ? var.logging.bucket_name : null
  s3_key_prefix = var.logging.destination == "s3" ? var.logging.s3_key_prefix : null

  # The log groups exist before Amazon Redshift writes to them, so their retention and
  # key apply.
  depends_on = [aws_cloudwatch_log_group.this]
}
