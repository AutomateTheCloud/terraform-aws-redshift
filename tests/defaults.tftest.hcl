# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Offline tests: every provider is mocked, so no AWS account is used.
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

# With only the required inputs: encrypted, the password in Secrets Manager, no network
# access, no public address, TLS required, a final snapshot, and no IAM permissions.
run "secure_defaults" {
  command = plan
  assert {
    condition     = aws_redshift_cluster.this.encrypted == "true"
    error_message = "The cluster must be encrypted."
  }
  assert {
    condition     = aws_redshift_cluster.this.manage_master_password == true && aws_redshift_cluster.this.master_password == null && aws_redshift_cluster.this.master_username == "awsuser"
    error_message = "The master password must be kept in Secrets Manager, for the awsuser master user."
  }
  assert {
    condition     = aws_redshift_cluster.this.publicly_accessible == false && aws_redshift_cluster.this.enhanced_vpc_routing == true
    error_message = "No public address, and enhanced VPC routing on, by default."
  }
  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.this) == 0 && length(aws_vpc_security_group_egress_rule.this) == 0
    error_message = "No ingress, and no egress besides S3, by default."
  }
  assert {
    condition     = aws_vpc_security_group_egress_rule.s3[0].from_port == 443 && aws_vpc_security_group_egress_rule.s3[0].to_port == 443 && aws_vpc_security_group_egress_rule.s3[0].ip_protocol == "tcp" && aws_vpc_security_group_egress_rule.s3[0].cidr_ipv4 == null
    error_message = "The only outbound rule is HTTPS to the S3 prefix list."
  }
  assert {
    condition     = data.aws_ec2_managed_prefix_list.s3[0].name == "com.amazonaws.us-east-1.s3"
    error_message = "Unexpected S3 prefix list name."
  }
  assert {
    condition     = one([for p in aws_redshift_parameter_group.this.parameter : p.value if p.name == "require_ssl"]) == "true" && length(aws_redshift_parameter_group.this.parameter) == 2
    error_message = "The parameter group must require TLS and set only the user activity log besides."
  }
  assert {
    condition     = aws_redshift_cluster.this.skip_final_snapshot == false && aws_redshift_cluster.this.automated_snapshot_retention_period == 7 && aws_redshift_cluster.this.manual_snapshot_retention_period == -1
    error_message = "A final snapshot and 7 days of automated snapshots by default."
  }
  assert {
    condition     = length(aws_iam_role_policy.this) == 0 && length(aws_iam_role_policy_attachment.this) == 0
    error_message = "The cluster's role must have no permissions by default."
  }
  assert {
    condition     = aws_redshift_cluster.this.cluster_type == "single-node" && aws_redshift_cluster.this.number_of_nodes == 1 && aws_redshift_cluster.this.multi_az == false && aws_redshift_cluster.this.port == 5439
    error_message = "Unexpected cluster shape defaults."
  }
  assert {
    condition     = length(aws_redshift_logging.this) == 0 && length(aws_cloudwatch_log_group.this) == 0 && length(aws_redshift_snapshot_schedule.this) == 0
    error_message = "No logging and no snapshot schedule by default."
  }
  assert {
    condition     = length(aws_sns_topic.this) == 2 && length(aws_cloudwatch_metric_alarm.this) == 5
    error_message = "Two topics and five alarms by default."
  }
  assert {
    condition     = aws_redshift_cluster.this.maintenance_track_name == "current" && aws_redshift_cluster.this.allow_version_upgrade == true && aws_redshift_cluster.this.cluster_version == "1.0"
    error_message = "Unexpected maintenance defaults."
  }
}

# Values known only after apply, from mocked resources.
run "defaults_after_apply" {
  command = apply
  assert {
    condition     = aws_redshift_cluster.this.default_iam_role_arn == aws_iam_role.this.arn && contains(tolist(aws_redshift_cluster.this.iam_roles), aws_iam_role.this.arn) && length(aws_redshift_cluster.this.iam_roles) == 1
    error_message = "The module's role must be the cluster's only and default role."
  }
  assert {
    condition     = can(regex("^analytics-final-[0-9a-f]{8}$", aws_redshift_cluster.this.final_snapshot_identifier))
    error_message = "Unexpected final snapshot name."
  }
  assert {
    condition     = jsondecode(aws_iam_role.this.assume_role_policy).Statement[0].Condition.StringEquals["aws:SourceAccount"] == "111111111111" && jsondecode(aws_iam_role.this.assume_role_policy).Statement[0].Principal.Service == "redshift.amazonaws.com"
    error_message = "The role must trust only Amazon Redshift in this account."
  }
  assert {
    condition     = startswith(aws_iam_role.this.name_prefix, "analytics-redshift-")
    error_message = "Unexpected role name prefix."
  }
  assert {
    condition     = jsondecode(aws_sns_topic_policy.this["critical"].policy).Statement[0].Condition.ArnLike["aws:SourceArn"] == "arn:aws:cloudwatch:us-east-1:111111111111:alarm:analytics-redshift-*"
    error_message = "The topic policy must allow only this cluster's alarms."
  }
  assert {
    condition     = output.metadata.redshift_logging == null && output.metadata.redshift_snapshot_schedule == null && output.metadata.iam_role_policy == null && output.metadata.vpc_security_group_ingress_rule == null && output.metadata.cloudwatch_log_group == null
    error_message = "Resources not created must be null in metadata."
  }
  assert {
    condition     = output.metadata.redshift_cluster.id == "analytics" && output.metadata.sns_topic["critical"].name == "analytics-redshift-critical" && output.metadata.cloudwatch_metric_alarm["health-critical"].alarm_name == "analytics-redshift-health-critical"
    error_message = "Unexpected metadata."
  }
  assert {
    condition     = !issensitive(output.metadata)
    error_message = "metadata must not be sensitive."
  }
}

run "abbreviation_override" {
  command = plan
  variables {
    details = { scope = "Test", purpose = "Data Warehouse", environment = "Production", environment_abbr = "prd", additional_tags = { CostCenter = "1234" } }
  }
  assert {
    condition     = output.metadata.details.environment.abbr == "prd" && output.metadata.details.purpose.abbr == "data_warehouse" && output.metadata.details.purpose.machine == "datawarehouse" && aws_redshift_cluster.this.tags["CostCenter"] == "1234" && aws_redshift_cluster.this.tags["Environment"] == "Production"
    error_message = "Unexpected details handling."
  }
}

run "empty_abbreviation_is_ignored" {
  command = plan
  variables {
    details = { scope = "Test", purpose = "Data Warehouse", environment = "Production", purpose_abbr = "" }
  }
  assert {
    condition     = output.metadata.details.purpose.abbr == "data_warehouse"
    error_message = "An empty abbreviation must fall back to the generated one."
  }
}

run "details_scope_required" {
  command = plan
  variables {
    details = { scope = " ", purpose = "P", environment = "E" }
  }
  expect_failures = [var.details]
}

run "details_purpose_required" {
  command = plan
  variables {
    details = { scope = "S", purpose = "", environment = "E" }
  }
  expect_failures = [var.details]
}

run "details_environment_required" {
  command = plan
  variables {
    details = { scope = "S", purpose = "P", environment = "" }
  }
  expect_failures = [var.details]
}
