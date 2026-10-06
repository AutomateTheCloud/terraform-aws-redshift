# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A single-node Amazon Redshift cluster in private subnets you give, reachable from
# anywhere in the VPC. Amazon Redshift keeps the master password in AWS Secrets Manager.

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

data "aws_vpc" "this" {
  id = var.vpc_id
}

module "redshift" {
  source = "../../"

  details = {
    scope       = "Example"
    purpose     = "Analytics"
    environment = "Development"
  }

  name          = "example-basic"
  node_type     = "ra3.large"
  vpc_id        = var.vpc_id
  subnet_ids    = var.subnet_ids
  database_name = "analytics"

  security_group_ingress = {
    vpc = { cidr_ipv4 = data.aws_vpc.this.cidr_block, description = "Anything in the VPC" }
  }
}

output "cluster" {
  description = "Where to connect, and the Secrets Manager secret that holds the master password"
  value = {
    dns_name        = module.redshift.metadata.redshift_cluster.dns_name
    port            = module.redshift.metadata.redshift_cluster.port
    database_name   = module.redshift.metadata.redshift_cluster.database_name
    master_username = module.redshift.metadata.redshift_cluster.master_username
    secret_arn      = module.redshift.metadata.redshift_cluster.master_password_secret_arn
  }
}
