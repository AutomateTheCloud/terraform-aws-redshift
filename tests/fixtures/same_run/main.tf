# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Test fixture: the network, the client security group, the KMS key, the log bucket's name,
# the policies and the password are created in the same run as the cluster, so their values
# are not known until apply.
terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

variable "own_password" {
  type    = bool
  default = false
}

resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "a" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "b" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.0.2.0/24"
}

resource "aws_security_group" "clients" {
  name        = "clients"
  description = "Clients of the cluster"
  vpc_id      = aws_vpc.this.id
}

resource "aws_kms_key" "this" {
  enable_key_rotation = true
}

# Stands in for a bucket created in the same run: its name is unknown at plan, too.
resource "random_id" "bucket" {
  prefix      = "data-"
  byte_length = 4
}

resource "aws_iam_role" "extra" {
  name_prefix = "extra-"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "redshift.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_policy" "extra" {
  name_prefix = "extra-"
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = "glue:GetTable", Resource = "*" }]
  })
}

data "aws_partition" "this" {}

data "aws_iam_policy_document" "read_data" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:${data.aws_partition.this.partition}:s3:::${random_id.bucket.hex}/*"]
  }
}

resource "random_password" "master" {
  length      = 24
  special     = false
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
}

module "redshift" {
  source = "../../.."

  details    = { scope = "Test", purpose = "Same Run", environment = "test" }
  name       = "same-run"
  node_type  = "ra3.large"
  vpc_id     = aws_vpc.this.id
  subnet_ids = [aws_subnet.a.id, aws_subnet.b.id]

  kms_key_id                        = aws_kms_key.this.arn
  master_password                   = var.own_password ? random_password.master.result : null
  master_password_secret_kms_key_id = var.own_password ? null : aws_kms_key.this.arn

  security_group_ingress = {
    clients = { security_group_id = aws_security_group.clients.id }
  }
  security_group_egress = {
    clients = { port = 443, security_group_id = aws_security_group.clients.id }
  }
  security_group_ids = [aws_security_group.clients.id]

  iam_role = {
    source_policy_documents = [data.aws_iam_policy_document.read_data.json]
    managed_policy_arns     = { extra = aws_iam_policy.extra.arn }
    additional_role_arns    = [aws_iam_role.extra.arn]
  }

  logging = { destination = "s3", bucket_name = random_id.bucket.hex }
  alarms  = { sns_kms_key_id = aws_kms_key.this.arn }
}
