# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# The role Amazon Redshift uses to reach other AWS services for the cluster. IAM names are
# unique in the account, across Regions, so the name is a prefix that AWS completes.
resource "aws_iam_role" "this" {
  name_prefix = "${trimsuffix(substr(var.name, 0, 28), "-")}-redshift-"
  description = "Amazon Redshift cluster ${var.name} in ${local.aws.region.name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "redshift.amazonaws.com" }
      Action    = "sts:AssumeRole"
      # Only for this account's clusters.
      Condition = { StringEquals = { "aws:SourceAccount" = local.aws.account.id } }
    }]
  })

  tags = local.tags

  # A new name replaces the role. Creating the new role first lets the cluster move to it
  # before the old one is deleted.
  lifecycle {
    create_before_destroy = true
  }
}
