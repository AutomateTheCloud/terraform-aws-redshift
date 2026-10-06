# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Bugs found in the module before 1.0.0, each with the input that showed it.
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

# security_group_rules defaulted to null, and every plan without it failed with
# "Iteration over null value". db_name defaulted to "", which the provider refuses, so
# every plan without it failed too. A null database name is unknown at plan (AWS creates
# dev), so this run checks only that the plan succeeds.
run "required_inputs_only_plan" {
  command = plan
  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.this) == 0
    error_message = "A cluster with no ingress rules and no database name must plan."
  }
}

# The master username defaulted to null, which AWS refuses when it creates a cluster.
run "master_username_has_a_default" {
  command = plan
  assert {
    condition     = aws_redshift_cluster.this.master_username == "awsuser"
    error_message = "The master username must default to awsuser."
  }
}

# An IPv6 range was sent as source_security_group_id.
run "ipv6_source_is_a_cidr" {
  command = plan
  variables {
    security_group_ingress = { v6 = { cidr_ipv6 = "2001:db8::/56" } }
  }
  assert {
    condition     = aws_vpc_security_group_ingress_rule.this["v6"].cidr_ipv6 == "2001:db8::/56" && aws_vpc_security_group_ingress_rule.this["v6"].referenced_security_group_id == null
    error_message = "An IPv6 range must be a cidr_ipv6 rule."
  }
}

# The IAM role was named rs-<name>: longer than IAM's 64 characters for a long name, and
# the same in every Region, so a second Region's cluster of the same name failed.
run "long_name_iam_role" {
  command = plan
  variables {
    name = "a23456789012345678901234567890123456789012345678901234567890123"
  }
  assert {
    condition     = length(aws_iam_role.this.name_prefix) <= 38 && aws_iam_role.this.name_prefix == "a234567890123456789012345678-redshift-"
    error_message = "The role's name prefix must leave room for the suffix IAM adds."
  }
  assert {
    condition     = strcontains(aws_iam_role.this.description, "us-east-1")
    error_message = "The global role should name the Region it is for."
  }
}

# The module opened every outbound connection (0.0.0.0/0, all protocols).
run "no_open_egress" {
  command = plan
  assert {
    condition     = length(aws_vpc_security_group_egress_rule.this) == 0 && aws_vpc_security_group_egress_rule.s3[0].cidr_ipv4 == null && aws_vpc_security_group_egress_rule.s3[0].ip_protocol == "tcp"
    error_message = "Only HTTPS to S3 may be allowed out by default."
  }
}

# permissions.athena and permissions.s3.read.all attached AmazonAthenaFullAccess and
# AmazonS3ReadOnlyAccess, for every bucket in the account, with arn:aws: ARNs that fail
# in other partitions. Now nothing is attached unless given.
run "no_broad_presets" {
  command = plan
  assert {
    condition     = length(aws_iam_role_policy_attachment.this) == 0
    error_message = "No managed policy may be attached by default."
  }
}

# The parameter group's description was built from details. A description change
# replaces a parameter group, and the cluster was still using it.
run "parameter_group_description_ignores_details" {
  command = plan
  variables {
    details = { scope = "Other", purpose = "Other", environment = "Other" }
  }
  assert {
    condition     = aws_redshift_parameter_group.this.description == "Redshift cluster analytics" && aws_redshift_parameter_group.this.name == "analytics-redshift-2-0"
    error_message = "The parameter group's description and name must not depend on details."
  }
}

# The generated password was kept in Terraform state, and could lack a lowercase letter,
# which AWS refuses. Amazon Redshift now generates it, in Secrets Manager.
run "no_generated_password_in_state" {
  command = plan
  assert {
    condition     = aws_redshift_cluster.this.master_password == null && aws_redshift_cluster.this.manage_master_password == true
    error_message = "Amazon Redshift must manage the password by default."
  }
}

# The SNS topics' policy let CloudWatch in any account publish to them.
run "topic_policy_names_the_account" {
  command = apply
  assert {
    condition     = jsondecode(aws_sns_topic_policy.this["warning"].policy).Statement[0].Condition.StringEquals["aws:SourceAccount"] == "111111111111"
    error_message = "The topic policy must be limited to this account."
  }
}

# The snapshot schedule was output as a list, unlike every other resource.
run "snapshot_schedule_output_is_an_object" {
  command = apply
  variables {
    backup = { schedules = ["rate(12 hours)"] }
  }
  assert {
    condition     = output.metadata.redshift_snapshot_schedule.identifier == "analytics" && output.metadata.redshift_snapshot_schedule_association.schedule_identifier == aws_redshift_snapshot_schedule.this[0].id
    error_message = "The snapshot schedule must be one object in metadata."
  }
}

# The warning disk alarm was named free_storage_space_percent-warning, unlike the
# critical one, and both measured space used, not free.
run "alarm_names" {
  command = plan
  assert {
    condition     = toset(keys(aws_cloudwatch_metric_alarm.this)) == toset(["health-critical", "cpu-critical", "cpu-warning", "disk-critical", "disk-warning"]) && aws_cloudwatch_metric_alarm.this["disk-warning"].alarm_name == "analytics-redshift-disk-warning" && aws_cloudwatch_metric_alarm.this["disk-warning"].metric_name == "PercentageDiskSpaceUsed"
    error_message = "Unexpected alarm names."
  }
  assert {
    condition     = alltrue([for a in aws_cloudwatch_metric_alarm.this : a.treat_missing_data == "missing"])
    error_message = "No data must keep an alarm's state, not set it off."
  }
}

# Found in AWS. AWS refuses a list of logs for the S3 destination ("Log exports can only
# be used with CloudWatch export"), and the module sent one.
run "s3_logging_sends_no_log_list" {
  command = plan
  variables {
    logging = { destination = "s3", bucket_name = "logs-bucket" }
  }
  assert {
    condition     = aws_redshift_logging.this[0].log_exports == null && one([for p in aws_redshift_parameter_group.this.parameter : p.value if p.name == "enable_user_activity_logging"]) == "true"
    error_message = "S3 logging must send no list of logs, and still turn on the user activity log."
  }
}

# Found in AWS. Provider 6.0.0 sent availability_zone_relocation_enabled only when true,
# AWS turned it on for the new RA3 cluster, and the next plan turned it off. The module
# now sets it either way.
run "availability_zone_relocation_is_set" {
  command = plan
  assert {
    condition     = aws_redshift_cluster.this.availability_zone_relocation_enabled == true
    error_message = "Availability Zone relocation must be set explicitly, on by default."
  }
}

# Found in AWS. Turning logging off left enable_user_activity_logging out of the parameter
# group; AWS kept it, and every plan tried to remove it again. The module now sets it either way.
run "user_activity_logging_parameter_always_set" {
  command = plan
  assert {
    condition     = one([for p in aws_redshift_parameter_group.this.parameter : p.value if p.name == "enable_user_activity_logging"]) == "false" && length(aws_redshift_parameter_group.this.parameter) == 2
    error_message = "enable_user_activity_logging must be set to false when the user activity log is off."
  }
}

# Found in AWS. A new alarm's insufficient_data_actions was saved as null and read back as
# [], so the first plan after an apply showed metadata changing. It is left out of metadata.
run "alarm_insufficient_data_actions_not_in_metadata" {
  command = apply
  assert {
    condition     = !can(output.metadata.cloudwatch_metric_alarm["cpu-critical"].insufficient_data_actions)
    error_message = "insufficient_data_actions must not be in metadata."
  }
}

# Last: the runs in a file share one state, and this apply would fill in the values
# that the plans above check.
# The cluster had a logging block, which AWS provider 6 removed, so every plan failed
# with "Unsupported block type". Logging is now the aws_redshift_logging resource.
run "logging_is_a_separate_resource" {
  command = apply
  variables {
    logging = { destination = "cloudwatch" }
  }
  assert {
    condition     = aws_redshift_logging.this[0].log_destination_type == "cloudwatch" && aws_redshift_logging.this[0].cluster_identifier == "analytics"
    error_message = "Logging must be configured through aws_redshift_logging."
  }
}
