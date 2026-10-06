# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

locals {
  # Without a password of the caller's own, Amazon Redshift keeps one in Secrets Manager.
  # Decided from whether the input is null, so a password created in the same run still
  # plans. Whether a password was given is not secret; without nonsensitive(), the
  # sensitive mark of master_password would make the whole metadata output sensitive.
  manage_master_password = nonsensitive(var.master_password == null)

  # The module's parameters, then the caller's, which win. Both are always set, to true or
  # false: a parameter left out of the group later keeps its value in AWS, and every plan
  # would try to remove it again.
  parameters = merge(
    {
      require_ssl                  = "true"
      enable_user_activity_logging = var.logging.destination != null && contains(var.logging.log_exports, "useractivitylog") ? "true" : "false"
    },
    var.parameter_group.parameters,
  )

  # One log group per log sent to CloudWatch Logs, keyed by the log's name.
  cloudwatch_log_groups = var.logging.destination == "cloudwatch" ? var.logging.log_exports : toset([])

  sns_topics = var.alarms.enabled ? toset(["critical", "warning"]) : toset([])

  # The alarms, keyed by a fixed name, from the inputs alone.
  alarms = var.alarms.enabled ? {
    health-critical = {
      topic       = "critical"
      metric      = "HealthStatus"
      comparison  = "LessThanThreshold"
      threshold   = 1
      periods     = 5
      description = "The cluster has reported itself unhealthy for 5 minutes."
    }
    cpu-critical = {
      topic       = "critical"
      metric      = "CPUUtilization"
      comparison  = "GreaterThanThreshold"
      threshold   = var.alarms.cpu_utilization.critical
      periods     = 5
      description = "Average CPU use has been above ${var.alarms.cpu_utilization.critical}% for 5 minutes."
    }
    cpu-warning = {
      topic       = "warning"
      metric      = "CPUUtilization"
      comparison  = "GreaterThanThreshold"
      threshold   = var.alarms.cpu_utilization.warning
      periods     = 5
      description = "Average CPU use has been above ${var.alarms.cpu_utilization.warning}% for 5 minutes."
    }
    disk-critical = {
      topic       = "critical"
      metric      = "PercentageDiskSpaceUsed"
      comparison  = "GreaterThanOrEqualToThreshold"
      threshold   = var.alarms.disk_space_used.critical
      periods     = 30
      description = "At least ${var.alarms.disk_space_used.critical}% of the disk space has been in use for 30 minutes."
    }
    disk-warning = {
      topic       = "warning"
      metric      = "PercentageDiskSpaceUsed"
      comparison  = "GreaterThanOrEqualToThreshold"
      threshold   = var.alarms.disk_space_used.warning
      periods     = 30
      description = "At least ${var.alarms.disk_space_used.warning}% of the disk space has been in use for 30 minutes."
    }
  } : {}
}
