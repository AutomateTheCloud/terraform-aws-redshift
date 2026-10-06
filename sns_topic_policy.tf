# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Lets CloudWatch publish to each topic, for this cluster's alarms only.
resource "aws_sns_topic_policy" "this" {
  for_each = local.sns_topics

  region = var.region
  arn    = aws_sns_topic.this[each.key].arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "CloudWatchAlarms"
      Effect    = "Allow"
      Principal = { Service = "cloudwatch.amazonaws.com" }
      Action    = "sns:Publish"
      Resource  = aws_sns_topic.this[each.key].arn
      Condition = {
        StringEquals = { "aws:SourceAccount" = local.aws.account.id }
        ArnLike      = { "aws:SourceArn" = "arn:${data.aws_partition.this.partition}:cloudwatch:${local.aws.region.name}:${local.aws.account.id}:alarm:${var.name}-redshift-*" }
      }
    }]
  })
}
