resource "aws_cloudwatch_metric_alarm" "cluster_health-critical" {
  alarm_name        = "${var.name}-rs-cluster_health-critical"
  alarm_description = "Cluster has entered unhealthy state"

  alarm_actions = [
    aws_sns_topic.critical.arn
  ]
  ok_actions = [
    aws_sns_topic.critical.arn
  ]
  insufficient_data_actions = []

  namespace   = "AWS/Redshift"
  metric_name = "HealthStatus"
  dimensions = {
    ClusterIdentifier = aws_redshift_cluster.this.id
  }

  comparison_operator = "LessThanThreshold"
  statistic           = "Average"
  evaluation_periods  = 5
  period              = 60
  threshold           = 1
  treat_missing_data  = "missing"

  tags     = local.tags
  provider = aws.this
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization-critical" {
  alarm_name        = "${var.name}-rs-cpu_utilization-critical"
  alarm_description = "Average CPU utilization above ${local.alarm.cpu_utilization.critical}%"

  alarm_actions = [
    aws_sns_topic.critical.arn
  ]
  ok_actions = [
    aws_sns_topic.critical.arn
  ]
  insufficient_data_actions = []

  namespace   = "AWS/Redshift"
  metric_name = "CPUUtilization"
  dimensions = {
    ClusterIdentifier = aws_redshift_cluster.this.id
  }

  comparison_operator = "GreaterThanThreshold"
  statistic           = "Average"
  evaluation_periods  = 5
  period              = 60
  threshold           = local.alarm.cpu_utilization.critical
  treat_missing_data  = "breaching"

  tags     = local.tags
  provider = aws.this
}

resource "aws_cloudwatch_metric_alarm" "free_storage_space-critical" {
  alarm_name        = "${var.name}-rs-free_storage_space-critical"
  alarm_description = "Consumed storage space has risen above ${local.alarm.free_storage_space.critical}%"

  alarm_actions = [
    aws_sns_topic.critical.arn
  ]
  ok_actions = [
    aws_sns_topic.critical.arn
  ]
  insufficient_data_actions = []

  namespace   = "AWS/Redshift"
  metric_name = "PercentageDiskSpaceUsed"
  dimensions = {
    ClusterIdentifier = aws_redshift_cluster.this.id
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Average"
  evaluation_periods  = 30
  period              = 60
  threshold           = local.alarm.free_storage_space.critical
  unit                = "Percent"
  treat_missing_data  = "breaching"

  tags     = local.tags
  provider = aws.this
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization-warning" {
  alarm_name        = "${var.name}-rs-cpu_utilization-warning"
  alarm_description = "Average CPU utilization above ${local.alarm.cpu_utilization.warning}%"

  alarm_actions = [
    aws_sns_topic.warning.arn
  ]
  ok_actions = [
    aws_sns_topic.warning.arn
  ]
  insufficient_data_actions = []

  namespace   = "AWS/Redshift"
  metric_name = "CPUUtilization"
  dimensions = {
    ClusterIdentifier = aws_redshift_cluster.this.id
  }

  comparison_operator = "GreaterThanThreshold"
  statistic           = "Average"
  evaluation_periods  = 5
  period              = 60
  threshold           = local.alarm.cpu_utilization.warning
  treat_missing_data  = "breaching"

  tags     = local.tags
  provider = aws.this
}

resource "aws_cloudwatch_metric_alarm" "free_storage_space-warning" {
  alarm_name        = "${var.name}-rs-free_storage_space_percent-warning"
  alarm_description = "Consumed storage space has risen above ${local.alarm.free_storage_space.warning}%"

  alarm_actions = [
    aws_sns_topic.warning.arn
  ]
  ok_actions = [
    aws_sns_topic.warning.arn
  ]
  insufficient_data_actions = []

  namespace   = "AWS/Redshift"
  metric_name = "PercentageDiskSpaceUsed"
  dimensions = {
    ClusterIdentifier = aws_redshift_cluster.this.id
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Average"
  evaluation_periods  = 30
  period              = 60
  threshold           = local.alarm.free_storage_space.warning
  unit                = "Percent"
  treat_missing_data  = "breaching"

  tags     = local.tags
  provider = aws.this
}
