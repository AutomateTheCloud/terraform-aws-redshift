# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
  mock_data "aws_partition" {
    defaults = { partition = "aws", reverse_dns_prefix = "com.amazonaws" }
  }
  mock_data "aws_ec2_managed_prefix_list" {
    defaults = { id = "pl-63a5400a" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
  mock_resource "aws_security_group" {
    defaults = { id = "sg-0123456789abcdef0", arn = "arn:aws:ec2:us-east-1:111111111111:security-group/sg-0123456789abcdef0" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::111111111111:role/analytics-redshift-1", name = "analytics-redshift-1", id = "analytics-redshift-1" }
  }
  mock_resource "aws_redshift_cluster" {
    defaults = { arn = "arn:aws:redshift:us-east-1:111111111111:cluster:analytics", id = "analytics" }
  }
  mock_resource "aws_sns_topic" {
    defaults = { arn = "arn:aws:sns:us-east-1:111111111111:analytics-redshift-topic" }
  }
}

variables {
  details    = { scope = "Test", purpose = "Analytics", environment = "test" }
  name       = "analytics"
  node_type  = "ra3.large"
  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
}

run "own_password" {
  command = plan
  variables {
    master_password = "Passw0rd-from-elsewhere"
  }
  assert {
    condition     = aws_redshift_cluster.this.manage_master_password == null && aws_redshift_cluster.this.master_password != null
    error_message = "With a password given, Amazon Redshift must not manage one: the provider refuses both."
  }
  assert {
    condition     = !issensitive(output.metadata.redshift_cluster.port)
    error_message = "A password must not make metadata sensitive."
  }
}

run "secret_and_storage_keys" {
  command = plan
  variables {
    kms_key_id                        = "arn:aws:kms:us-east-1:111111111111:key/data"
    master_password_secret_kms_key_id = "arn:aws:kms:us-east-1:111111111111:key/secret"
  }
  assert {
    condition     = aws_redshift_cluster.this.kms_key_id == "arn:aws:kms:us-east-1:111111111111:key/data" && aws_redshift_cluster.this.master_password_secret_kms_key_id == "arn:aws:kms:us-east-1:111111111111:key/secret"
    error_message = "The keys must reach the cluster."
  }
}

run "multi_node" {
  command = plan
  variables {
    number_of_nodes              = 4
    multi_az                     = true
    availability_zone_relocation = false
  }
  assert {
    condition     = aws_redshift_cluster.this.cluster_type == "multi-node" && aws_redshift_cluster.this.number_of_nodes == 4 && aws_redshift_cluster.this.multi_az == true && aws_redshift_cluster.this.availability_zone_relocation_enabled == false
    error_message = "Unexpected multi-node settings."
  }
}

run "cloudwatch_logging" {
  command = plan
  variables {
    logging = { destination = "cloudwatch", retention_in_days = 30, kms_key_id = "arn:aws:kms:us-east-1:111111111111:key/logs" }
  }
  assert {
    condition     = toset(keys(aws_cloudwatch_log_group.this)) == toset(["connectionlog", "userlog", "useractivitylog"]) && aws_cloudwatch_log_group.this["userlog"].name == "/aws/redshift/cluster/analytics/userlog" && aws_cloudwatch_log_group.this["userlog"].retention_in_days == 30 && aws_cloudwatch_log_group.this["userlog"].kms_key_id == "arn:aws:kms:us-east-1:111111111111:key/logs"
    error_message = "Unexpected log groups."
  }
  assert {
    condition     = aws_redshift_logging.this[0].log_exports == toset(["connectionlog", "userlog", "useractivitylog"]) && aws_redshift_logging.this[0].bucket_name == null
    error_message = "Unexpected logging settings."
  }
  assert {
    condition     = one([for p in aws_redshift_parameter_group.this.parameter : p.value if p.name == "enable_user_activity_logging"]) == "true"
    error_message = "The user activity log needs enable_user_activity_logging."
  }
}

run "s3_logging_without_user_activity" {
  command = plan
  variables {
    logging = { destination = "s3", bucket_name = "logs-bucket", s3_key_prefix = "redshift/", log_exports = ["connectionlog", "userlog"], retention_in_days = 30 }
  }
  assert {
    condition     = length(aws_cloudwatch_log_group.this) == 0 && aws_redshift_logging.this[0].log_exports == null && aws_redshift_logging.this[0].bucket_name == "logs-bucket" && aws_redshift_logging.this[0].s3_key_prefix == "redshift/" && aws_redshift_logging.this[0].log_destination_type == "s3"
    error_message = "Unexpected S3 logging settings."
  }
  assert {
    condition     = one([for p in aws_redshift_parameter_group.this.parameter : p.value if p.name == "enable_user_activity_logging"]) == "false"
    error_message = "enable_user_activity_logging must be false without the user activity log."
  }
}

run "caller_parameters_win" {
  command = plan
  variables {
    parameter_group = {
      family = "redshift-1.0"
      parameters = {
        require_ssl            = "false"
        wlm_json_configuration = "[{\"auto_wlm\":true}]"
      }
    }
  }
  assert {
    condition     = one([for p in aws_redshift_parameter_group.this.parameter : p.value if p.name == "require_ssl"]) == "false" && length(aws_redshift_parameter_group.this.parameter) == 3
    error_message = "The caller's parameters must override the module's."
  }
  assert {
    condition     = aws_redshift_parameter_group.this.family == "redshift-1.0" && aws_redshift_parameter_group.this.name == "analytics-redshift-1-0"
    error_message = "The family must be part of the name."
  }
}

run "snapshot_schedules" {
  command = plan
  variables {
    backup = { retention_period = 14, schedules = ["rate(12 hours)", "cron(0 3 * * ? *)"] }
  }
  assert {
    condition     = aws_redshift_snapshot_schedule.this[0].identifier == "analytics" && aws_redshift_snapshot_schedule.this[0].definitions == toset(["rate(12 hours)", "cron(0 3 * * ? *)"]) && aws_redshift_cluster.this.automated_snapshot_retention_period == 14
    error_message = "Unexpected snapshot schedule."
  }
}

run "alarms_off" {
  command = plan
  variables {
    alarms = { enabled = false }
  }
  assert {
    condition     = length(aws_sns_topic.this) == 0 && length(aws_sns_topic_policy.this) == 0 && length(aws_cloudwatch_metric_alarm.this) == 0 && output.metadata.sns_topic == null && output.metadata.cloudwatch_metric_alarm == null
    error_message = "No alarms or topics when they are off."
  }
}

run "alarm_thresholds_and_topic_key" {
  command = plan
  variables {
    alarms = {
      cpu_utilization = { critical = 95, warning = 85 }
      disk_space_used = { critical = 75, warning = 60 }
      sns_kms_key_id  = "arn:aws:kms:us-east-1:111111111111:key/sns"
    }
  }
  assert {
    condition     = aws_cloudwatch_metric_alarm.this["cpu-critical"].threshold == 95 && aws_cloudwatch_metric_alarm.this["cpu-warning"].threshold == 85 && aws_cloudwatch_metric_alarm.this["disk-critical"].threshold == 75 && aws_cloudwatch_metric_alarm.this["disk-warning"].threshold == 60 && aws_cloudwatch_metric_alarm.this["health-critical"].threshold == 1
    error_message = "Unexpected thresholds."
  }
  assert {
    condition     = aws_sns_topic.this["critical"].kms_master_key_id == "arn:aws:kms:us-east-1:111111111111:key/sns" && aws_sns_topic.this["warning"].kms_master_key_id == "arn:aws:kms:us-east-1:111111111111:key/sns"
    error_message = "The topics must use the key."
  }
  assert {
    condition     = aws_cloudwatch_metric_alarm.this["disk-warning"].evaluation_periods == 30 && aws_cloudwatch_metric_alarm.this["cpu-warning"].evaluation_periods == 5 && aws_cloudwatch_metric_alarm.this["health-critical"].comparison_operator == "LessThanThreshold"
    error_message = "Unexpected alarm definitions."
  }
}

run "network_options" {
  command = plan
  variables {
    port                 = 8192
    allow_s3_egress      = false
    enhanced_vpc_routing = false
    publicly_accessible  = true
    security_group_ids   = ["sg-0fedcba9876543210"]
    security_group_ingress = {
      app   = { security_group_id = "sg-0aaaaaaaaaaaaaaaa", description = "Application servers" }
      admin = { prefix_list_id = "pl-0123456789abcdef0" }
    }
    security_group_egress = {
      orders_db = { port = 5432, security_group_id = "sg-0bbbbbbbbbbbbbbbb" }
    }
  }
  assert {
    condition     = aws_vpc_security_group_ingress_rule.this["app"].from_port == 8192 && aws_vpc_security_group_ingress_rule.this["app"].to_port == 8192 && aws_vpc_security_group_ingress_rule.this["app"].description == "Application servers" && aws_vpc_security_group_ingress_rule.this["admin"].description == "admin"
    error_message = "The ingress rules must use the cluster's port."
  }
  assert {
    condition     = length(aws_vpc_security_group_egress_rule.s3) == 0 && length(data.aws_ec2_managed_prefix_list.s3) == 0 && aws_vpc_security_group_egress_rule.this["orders_db"].from_port == 5432
    error_message = "Unexpected egress rules."
  }
  assert {
    condition     = aws_redshift_cluster.this.port == 8192 && aws_redshift_cluster.this.publicly_accessible == true && aws_redshift_cluster.this.enhanced_vpc_routing == false && contains(aws_redshift_cluster.this.vpc_security_group_ids, "sg-0fedcba9876543210")
    error_message = "Unexpected cluster network settings."
  }
}

run "restore_and_maintenance" {
  command = plan
  variables {
    snapshot_identifier = "analytics-final-0a1b2c3d"
    skip_final_snapshot = true
    database_name       = "sales"
    master_username     = "admin"
    maintenance         = { window = "sun:05:00-sun:05:30", allow_version_upgrade = false, track_name = "trailing" }
    backup              = { manual_snapshot_retention_period = 30 }
    timeouts            = { create = "3h" }
  }
  assert {
    condition     = aws_redshift_cluster.this.snapshot_identifier == "analytics-final-0a1b2c3d" && aws_redshift_cluster.this.skip_final_snapshot == true && aws_redshift_cluster.this.database_name == "sales" && aws_redshift_cluster.this.master_username == "admin"
    error_message = "Unexpected restore settings."
  }
  assert {
    condition     = aws_redshift_cluster.this.preferred_maintenance_window == "sun:05:00-sun:05:30" && aws_redshift_cluster.this.allow_version_upgrade == false && aws_redshift_cluster.this.maintenance_track_name == "trailing" && aws_redshift_cluster.this.manual_snapshot_retention_period == 30
    error_message = "Unexpected maintenance settings."
  }
  assert {
    condition     = aws_redshift_cluster.this.timeouts.create == "3h" && aws_redshift_cluster.this.timeouts.delete == "120m"
    error_message = "Unexpected timeouts."
  }
}

# Last: an apply, and the runs in a file share one state.
run "iam_role_permissions" {
  command = apply
  variables {
    iam_role = {
      source_policy_documents = ["{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"s3:GetObject\",\"Resource\":\"arn:aws:s3:::data/*\"}]}"]
      managed_policy_arns     = { glue = "arn:aws:iam::111111111111:policy/glue-read" }
      additional_role_arns    = ["arn:aws:iam::111111111111:role/spectrum"]
    }
  }
  assert {
    condition     = length(aws_iam_role_policy.this) == 1 && aws_iam_role_policy_attachment.this["glue"].policy_arn == "arn:aws:iam::111111111111:policy/glue-read"
    error_message = "Unexpected role permissions."
  }
  assert {
    condition     = contains(tolist(aws_redshift_cluster.this.iam_roles), "arn:aws:iam::111111111111:role/spectrum")
    error_message = "Additional roles must be associated with the cluster."
  }
}
