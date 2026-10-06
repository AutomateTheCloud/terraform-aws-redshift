# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = local.alarms

  region            = var.region
  alarm_name        = "${var.name}-redshift-${each.key}"
  alarm_description = each.value.description

  namespace           = "AWS/Redshift"
  metric_name         = each.value.metric
  dimensions          = { ClusterIdentifier = aws_redshift_cluster.this.id }
  statistic           = "Average"
  period              = 60
  evaluation_periods  = each.value.periods
  comparison_operator = each.value.comparison
  threshold           = each.value.threshold
  # No data, such as while the cluster is paused, keeps the alarm's last state.
  treat_missing_data = "missing"

  alarm_actions = [aws_sns_topic.this[each.value.topic].arn]
  ok_actions    = [aws_sns_topic.this[each.value.topic].arn]

  tags = local.tags
}
