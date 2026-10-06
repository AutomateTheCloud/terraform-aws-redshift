# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Most of the module's options together: two nodes, a KMS key of your own for the data,
# the password secret and the alarm topics, read access to one S3 bucket for COPY, access
# from one security group only, audit logs in CloudWatch Logs, a snapshot schedule and
# workload management settings.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "vpc_id" {
  description = "ID of the VPC to create the cluster in"
  type        = string
}

variable "subnet_ids" {
  description = "IDs of private subnets for the cluster, in at least two Availability Zones"
  type        = list(string)
}

variable "data_bucket_name" {
  description = "Name of an existing S3 bucket, in the same Region, that the cluster may read with COPY"
  type        = string
}

data "aws_caller_identity" "this" {}

data "aws_partition" "this" {}

# The application's instances. Only members of this group can reach the cluster.
resource "aws_security_group" "app" {
  name        = "example-complete-app"
  description = "Application servers that query the data warehouse"
  vpc_id      = var.vpc_id
}

# Encrypts the cluster's data and snapshots, the Secrets Manager secret and the alarm
# topics. The first statement lets IAM policies in this account grant its use; the second
# lets CloudWatch publish alarms to the encrypted topics.
data "aws_iam_policy_document" "key" {
  statement {
    sid       = "Account"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.this.partition}:iam::${data.aws_caller_identity.this.account_id}:root"]
    }
  }

  statement {
    sid       = "CloudWatchAlarms"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey*"]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.this.account_id]
    }
  }
}

resource "aws_kms_key" "this" {
  description             = "example-complete data warehouse"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.key.json
}

# Read access to one bucket, for COPY ... IAM_ROLE default.
data "aws_iam_policy_document" "read_data" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:${data.aws_partition.this.partition}:s3:::${var.data_bucket_name}"]
  }

  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:${data.aws_partition.this.partition}:s3:::${var.data_bucket_name}/*"]
  }
}

module "redshift" {
  source = "../../"

  details = {
    scope       = "Example"
    purpose     = "Analytics"
    environment = "Production"
    additional_tags = {
      CostCenter = "1234"
    }
  }

  name            = "example-complete"
  node_type       = "ra3.large"
  number_of_nodes = 2
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids
  database_name   = "analytics"
  master_username = "warehouse_admin"

  kms_key_id                        = aws_kms_key.this.arn
  master_password_secret_kms_key_id = aws_kms_key.this.arn

  security_group_ingress = {
    app = { security_group_id = aws_security_group.app.id, description = "Application servers" }
  }

  iam_role = {
    source_policy_documents = [data.aws_iam_policy_document.read_data.json]
  }

  parameter_group = {
    parameters = {
      # Automatic workload management, with short queries run first.
      wlm_json_configuration = jsonencode([
        { auto_wlm = true },
        { short_query_queue = true },
      ])
      # At most one concurrency scaling cluster for busy periods.
      max_concurrency_scaling_clusters = "1"
    }
  }

  backup = {
    retention_period = 14
    schedules        = ["rate(12 hours)"]
  }

  maintenance = {
    window = "sun:05:00-sun:05:30"
  }

  logging = {
    destination       = "cloudwatch"
    retention_in_days = 30
  }

  alarms = {
    cpu_utilization = { critical = 95, warning = 85 }
    sns_kms_key_id  = aws_kms_key.this.arn
  }
}

output "cluster" {
  description = "Where to connect, the Secrets Manager secret that holds the master password, and the alarm topics to subscribe to"
  value = {
    dns_name           = module.redshift.metadata.redshift_cluster.dns_name
    port               = module.redshift.metadata.redshift_cluster.port
    database_name      = module.redshift.metadata.redshift_cluster.database_name
    master_username    = module.redshift.metadata.redshift_cluster.master_username
    secret_arn         = module.redshift.metadata.redshift_cluster.master_password_secret_arn
    iam_role_arn       = module.redshift.metadata.iam_role.arn
    alarm_topics       = { for k, t in module.redshift.metadata.sns_topic : k => t.arn }
    app_security_group = aws_security_group.app.id
  }
}
