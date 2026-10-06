# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Every validation: one value it refuses, and values at the edge of what it accepts.
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

run "alarms_critical_over_100" {
  command = plan
  variables {
    alarms = { cpu_utilization = { critical = 101 } }
  }
  expect_failures = [var.alarms]
}

run "alarms_warning_over_critical" {
  command = plan
  variables {
    alarms = { disk_space_used = { critical = 80, warning = 85 } }
  }
  expect_failures = [var.alarms]
}

run "alarms_zero_warning" {
  command = plan
  variables {
    alarms = { cpu_utilization = { warning = 0 } }
  }
  expect_failures = [var.alarms]
}

run "alarms_kms_not_arn" {
  command = plan
  variables {
    alarms = { sns_kms_key_id = "alias/sns" }
  }
  expect_failures = [var.alarms]
}

run "backup_retention_zero" {
  command = plan
  variables {
    backup = { retention_period = 0 }
  }
  expect_failures = [var.backup]
}

run "backup_retention_36" {
  command = plan
  variables {
    backup = { retention_period = 36 }
  }
  expect_failures = [var.backup]
}

run "backup_retention_fraction" {
  command = plan
  variables {
    backup = { retention_period = 1.5 }
  }
  expect_failures = [var.backup]
}

run "backup_manual_zero" {
  command = plan
  variables {
    backup = { manual_snapshot_retention_period = 0 }
  }
  expect_failures = [var.backup]
}

run "backup_manual_3654" {
  command = plan
  variables {
    backup = { manual_snapshot_retention_period = 3654 }
  }
  expect_failures = [var.backup]
}

run "backup_schedule_bad" {
  command = plan
  variables {
    backup = { schedules = ["every 12 hours"] }
  }
  expect_failures = [var.backup]
}

run "backup_schedule_minutes" {
  command = plan
  variables {
    backup = { schedules = ["rate(30 minutes)"] }
  }
  expect_failures = [var.backup]
}

run "database_name_upper" {
  command = plan
  variables {
    database_name = "Analytics"
  }
  expect_failures = [var.database_name]
}

run "database_name_digit_first" {
  command = plan
  variables {
    database_name = "1db"
  }
  expect_failures = [var.database_name]
}

run "database_name_65" {
  command = plan
  variables {
    database_name = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  }
  expect_failures = [var.database_name]
}

run "iam_role_policy_not_arn" {
  command = plan
  variables {
    iam_role = { managed_policy_arns = { s3 = "AmazonS3ReadOnlyAccess" } }
  }
  expect_failures = [var.iam_role]
}

run "iam_role_too_many_roles" {
  command = plan
  variables {
    iam_role = { additional_role_arns = [for i in range(50) : "arn:aws:iam::111111111111:role/r${i}"] }
  }
  expect_failures = [var.iam_role]
}

run "kms_key_not_arn" {
  command = plan
  variables {
    kms_key_id = "alias/redshift"
  }
  expect_failures = [var.kms_key_id]
}

run "logging_destination_bad" {
  command = plan
  variables {
    logging = { destination = "firehose" }
  }
  expect_failures = [var.logging]
}

run "logging_exports_empty" {
  command = plan
  variables {
    logging = { destination = "cloudwatch", log_exports = [] }
  }
  expect_failures = [var.logging]
}

run "logging_exports_bad" {
  command = plan
  variables {
    logging = { destination = "cloudwatch", log_exports = ["querylog"] }
  }
  expect_failures = [var.logging]
}

run "logging_s3_needs_bucket" {
  command = plan
  variables {
    logging = { destination = "s3" }
  }
  expect_failures = [var.logging]
}

run "logging_bucket_without_s3" {
  command = plan
  variables {
    logging = { destination = "cloudwatch", bucket_name = "logs" }
  }
  expect_failures = [var.logging]
}

run "logging_retention_bad" {
  command = plan
  variables {
    logging = { destination = "cloudwatch", retention_in_days = 2 }
  }
  expect_failures = [var.logging]
}

run "logging_kms_not_arn" {
  command = plan
  variables {
    logging = { destination = "cloudwatch", kms_key_id = "alias/logs" }
  }
  expect_failures = [var.logging]
}

run "maintenance_window_bad" {
  command = plan
  variables {
    maintenance = { window = "Sun:05:00-Sun:05:30" }
  }
  expect_failures = [var.maintenance]
}

run "maintenance_track_bad" {
  command = plan
  variables {
    maintenance = { track_name = "latest" }
  }
  expect_failures = [var.maintenance]
}

run "secret_kms_not_arn" {
  command = plan
  variables {
    master_password_secret_kms_key_id = "alias/secrets"
  }
  expect_failures = [var.master_password_secret_kms_key_id]
}

run "secret_kms_with_password" {
  command = plan
  variables {
    master_password_secret_kms_key_id = "arn:aws:kms:us-east-1:111111111111:key/k"
    master_password                   = "Passw0rd-ok"
  }
  expect_failures = [var.master_password_secret_kms_key_id]
}

run "master_username_upper" {
  command = plan
  variables {
    master_username = "Admin"
  }
  expect_failures = [var.master_username]
}

run "master_username_public" {
  command = plan
  variables {
    master_username = "public"
  }
  expect_failures = [var.master_username]
}

run "master_username_digit_first" {
  command = plan
  variables {
    master_username = "1admin"
  }
  expect_failures = [var.master_username]
}

run "multi_az_dc2" {
  command = plan
  variables {
    multi_az  = true
    node_type = "dc2.large"
  }
  expect_failures = [var.multi_az]
}

run "name_upper" {
  command = plan
  variables {
    name = "Analytics"
  }
  expect_failures = [var.name]
}

run "name_double_hyphen" {
  command = plan
  variables {
    name = "a--b"
  }
  expect_failures = [var.name]
}

run "name_trailing_hyphen" {
  command = plan
  variables {
    name = "a-"
  }
  expect_failures = [var.name]
}

run "name_64" {
  command = plan
  variables {
    name = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  }
  expect_failures = [var.name]
}

run "node_type_bad" {
  command = plan
  variables {
    node_type = "ra3"
  }
  expect_failures = [var.node_type]
}

run "nodes_zero" {
  command = plan
  variables {
    number_of_nodes = 0
  }
  expect_failures = [var.number_of_nodes]
}

run "nodes_129" {
  command = plan
  variables {
    number_of_nodes = 129
  }
  expect_failures = [var.number_of_nodes]
}

run "nodes_fraction" {
  command = plan
  variables {
    number_of_nodes = 2.5
  }
  expect_failures = [var.number_of_nodes]
}

run "parameter_family_bad" {
  command = plan
  variables {
    parameter_group = { family = "postgres16" }
  }
  expect_failures = [var.parameter_group]
}

run "port_ra3_5430" {
  command = plan
  variables {
    port = 5430
  }
  expect_failures = [var.port]
}

run "port_ra3_5456" {
  command = plan
  variables {
    port = 5456
  }
  expect_failures = [var.port]
}

run "port_ra3_8216" {
  command = plan
  variables {
    port = 8216
  }
  expect_failures = [var.port]
}

run "port_rg_1150" {
  command = plan
  variables {
    port      = 1150
    node_type = "rg.large"
  }
  expect_failures = [var.port]
}

run "port_dc2_1149" {
  command = plan
  variables {
    port      = 1149
    node_type = "dc2.large"
  }
  expect_failures = [var.port]
}

run "egress_two_destinations" {
  command = plan
  variables {
    security_group_egress = { x = { port = 443, cidr_ipv4 = "10.0.0.0/8", prefix_list_id = "pl-1" } }
  }
  expect_failures = [var.security_group_egress]
}

run "egress_no_destination" {
  command = plan
  variables {
    security_group_egress = { x = { port = 443 } }
  }
  expect_failures = [var.security_group_egress]
}

run "egress_bad_cidr" {
  command = plan
  variables {
    security_group_egress = { x = { port = 443, cidr_ipv4 = "10.0.0.0" } }
  }
  expect_failures = [var.security_group_egress]
}

run "egress_port_zero" {
  command = plan
  variables {
    security_group_egress = { x = { port = 0, cidr_ipv4 = "10.0.0.0/8" } }
  }
  expect_failures = [var.security_group_egress]
}

run "ingress_two_sources" {
  command = plan
  variables {
    security_group_ingress = { x = { cidr_ipv4 = "10.0.0.0/8", security_group_id = "sg-1" } }
  }
  expect_failures = [var.security_group_ingress]
}

run "ingress_no_source" {
  command = plan
  variables {
    security_group_ingress = { x = { description = "nothing" } }
  }
  expect_failures = [var.security_group_ingress]
}

run "ingress_ipv4_as_ipv6" {
  command = plan
  variables {
    security_group_ingress = { x = { cidr_ipv6 = "10.0.0.0/8" } }
  }
  expect_failures = [var.security_group_ingress]
}

run "relocation_needs_two_subnets" {
  command = plan
  variables {
    subnet_ids = ["subnet-0123456789abcdef0"]
  }
  expect_failures = [var.availability_zone_relocation]
}

run "one_subnet_without_relocation" {
  command = plan
  variables {
    subnet_ids                   = ["subnet-0123456789abcdef0"]
    availability_zone_relocation = false
  }
}

run "subnet_ids_empty" {
  command = plan
  variables {
    subnet_ids                   = []
    availability_zone_relocation = false
  }
  expect_failures = [var.subnet_ids]
}

run "subnet_ids_bad" {
  command = plan
  variables {
    subnet_ids = ["subnet-0123456789abcdef0", "sg-0123456789abcdef0"]
  }
  expect_failures = [var.subnet_ids]
}

run "timeouts_bad" {
  command = plan
  variables {
    timeouts = { create = "2 hours" }
  }
  expect_failures = [var.timeouts]
}

run "vpc_id_bad" {
  command = plan
  variables {
    vpc_id = "0123456789abcdef0"
  }
  expect_failures = [var.vpc_id]
}

run "alarms_boundaries" {
  command = plan
  variables {
    alarms = { cpu_utilization = { critical = 100, warning = 100 }, disk_space_used = { critical = 50, warning = 1 }, sns_kms_key_id = "arn:aws:kms:us-east-1:111111111111:key/k" }
  }
}

run "backup_boundaries" {
  command = plan
  variables {
    backup = { retention_period = 35, manual_snapshot_retention_period = 3653, schedules = ["rate(1 hour)", "rate(12 hours)", "cron(0 3 * * ? *)"] }
  }
}

run "backup_lower_boundaries" {
  command = plan
  variables {
    backup = { retention_period = 1, manual_snapshot_retention_period = 1 }
  }
}

run "database_name_allowed" {
  command = plan
  variables {
    database_name = "_sales$2026"
  }
}

run "database_name_64" {
  command = plan
  variables {
    database_name = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  }
}

run "master_username_allowed" {
  command = plan
  variables {
    master_username = "etl.admin+1@x-y_z"
  }
}

run "name_63" {
  command = plan
  variables {
    name = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  }
}

run "name_with_hyphens" {
  command = plan
  variables {
    name = "a-1-b"
  }
}

run "nodes_128" {
  command = plan
  variables {
    number_of_nodes = 128
  }
}

run "port_ra3_ranges_low" {
  command = plan
  variables {
    port = 5431
  }
}

run "port_ra3_ranges_high" {
  command = plan
  variables {
    port = 8215
  }
}

run "port_dc2_range" {
  command = plan
  variables {
    port      = 65535
    node_type = "dc2.large"
  }
}

run "port_dc2_low" {
  command = plan
  variables {
    port      = 1150
    node_type = "dc2.large"
  }
}

run "multi_az_ra3" {
  command = plan
  variables {
    multi_az                     = true
    availability_zone_relocation = false
    number_of_nodes              = 2
  }
}

run "multi_az_with_relocation" {
  command = plan
  variables {
    multi_az        = true
    number_of_nodes = 2
  }
  expect_failures = [var.multi_az]
}

run "logging_s3" {
  command = plan
  variables {
    logging = { destination = "s3", bucket_name = "logs", s3_key_prefix = "redshift/" }
  }
}

run "logging_cloudwatch_forever" {
  command = plan
  variables {
    logging = { destination = "cloudwatch", retention_in_days = 0, log_exports = ["connectionlog"] }
  }
}

run "ingress_every_source_kind" {
  command = plan
  variables {
    security_group_ingress = {
      a = { cidr_ipv4 = "10.0.0.0/16" }
      b = { cidr_ipv6 = "2001:db8::/56" }
      c = { security_group_id = "sg-0123456789abcdef0" }
      d = { prefix_list_id = "pl-0123456789abcdef0" }
    }
  }
}

run "timeouts_units" {
  command = plan
  variables {
    timeouts = { create = "90m", update = "3h", delete = "3600s" }
  }
}

run "iam_role_49_roles" {
  command = plan
  variables {
    iam_role = { additional_role_arns = [for i in range(49) : "arn:aws:iam::111111111111:role/r${i}"] }
  }
}
