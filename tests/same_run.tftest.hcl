# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Inputs created in the same run: the VPC, subnets, client security group, KMS key, log
# bucket, policies and password are unknown at plan time. The old module failed to plan
# with a client security group ("Invalid for_each argument") or a KMS key ("Invalid count
# argument") from the same run, and found its subnets by tag, which misses new ones.
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
  mock_resource "aws_kms_key" {
    defaults = { arn = "arn:aws:kms:us-east-1:111111111111:key/same-run" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::111111111111:role/same-run" }
  }
  mock_resource "aws_iam_policy" {
    defaults = { arn = "arn:aws:iam::111111111111:policy/same-run" }
  }
}

run "same_run_plans" {
  command = plan
  module {
    source = "./tests/fixtures/same_run"
  }
}

run "same_run_with_own_password_plans" {
  command = plan
  module {
    source = "./tests/fixtures/same_run"
  }
  variables {
    own_password = true
  }
}
