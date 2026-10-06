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

run "provider_region_by_default" {
  command = plan
  assert {
    condition     = output.metadata.aws.region.name == "us-east-1"
    error_message = "Expected the provider's Region."
  }
}

run "region_reaches_every_resource" {
  command = apply
  variables {
    region                 = "us-west-2"
    logging                = { destination = "cloudwatch" }
    backup                 = { schedules = ["rate(12 hours)"] }
    security_group_ingress = { vpc = { cidr_ipv4 = "10.0.0.0/16" } }
    security_group_egress  = { dynamodb = { port = 443, prefix_list_id = "pl-00a54069" } }
  }
  assert {
    condition = alltrue(concat([
      aws_redshift_cluster.this.region == "us-west-2",
      aws_redshift_subnet_group.this.region == "us-west-2",
      aws_redshift_parameter_group.this.region == "us-west-2",
      aws_redshift_snapshot_schedule.this[0].region == "us-west-2",
      aws_redshift_snapshot_schedule_association.this[0].region == "us-west-2",
      aws_redshift_logging.this[0].region == "us-west-2",
      aws_security_group.this.region == "us-west-2",
      aws_vpc_security_group_ingress_rule.this["vpc"].region == "us-west-2",
      aws_vpc_security_group_egress_rule.this["dynamodb"].region == "us-west-2",
      aws_vpc_security_group_egress_rule.s3[0].region == "us-west-2",
      data.aws_ec2_managed_prefix_list.s3[0].region == "us-west-2",
      data.aws_region.this.region == "us-west-2",
      output.metadata.aws.region.name == "us-west-2",
      ],
      [for g in aws_cloudwatch_log_group.this : g.region == "us-west-2"],
      [for t in aws_sns_topic.this : t.region == "us-west-2"],
      [for p in aws_sns_topic_policy.this : p.region == "us-west-2"],
      [for a in aws_cloudwatch_metric_alarm.this : a.region == "us-west-2"],
    ))
    error_message = "region was not passed through to every resource."
  }
  assert {
    condition     = strcontains(aws_iam_role.this.description, "us-west-2") && strcontains(jsondecode(aws_sns_topic_policy.this["critical"].policy).Statement[0].Condition.ArnLike["aws:SourceArn"], ":cloudwatch:us-west-2:")
    error_message = "The role and topic policy should name the Region."
  }
}

# Any Region plans, including ones added after this module was written.
run "region_not_in_old_tables" {
  command = plan
  variables { region = "ap-southeast-7" }
  assert {
    condition     = output.metadata.aws.region.abbr == "apse7" && data.aws_ec2_managed_prefix_list.s3[0].name == "com.amazonaws.ap-southeast-7.s3"
    error_message = "Unexpected abbreviation or prefix list."
  }
}

run "region_abbreviation_mexico" {
  command = plan
  variables { region = "mx-central-1" }
  assert {
    condition     = output.metadata.aws.region.abbr == "mxc1"
    error_message = "Unexpected abbreviation."
  }
}

run "region_abbreviation_override" {
  command = plan
  variables { region = "us-gov-west-1" }
  assert {
    condition     = output.metadata.aws.region.abbr == "ugw1"
    error_message = "Unexpected abbreviation."
  }
}

# Other partitions: the S3 prefix list name and the topic policy's ARN follow the partition.
run "partition_aws_cn" {
  command = apply
  variables { region = "cn-north-1" }
  override_data {
    target = data.aws_partition.this
    values = { partition = "aws-cn", reverse_dns_prefix = "cn.com.amazonaws" }
  }
  assert {
    condition     = data.aws_ec2_managed_prefix_list.s3[0].name == "cn.com.amazonaws.cn-north-1.s3"
    error_message = "The prefix list name must use the partition's DNS prefix."
  }
  assert {
    condition     = startswith(jsondecode(aws_sns_topic_policy.this["critical"].policy).Statement[0].Condition.ArnLike["aws:SourceArn"], "arn:aws-cn:cloudwatch:cn-north-1:")
    error_message = "The topic policy's ARN must use the partition."
  }
}
