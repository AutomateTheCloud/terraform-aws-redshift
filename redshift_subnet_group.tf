# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_redshift_subnet_group" "this" {
  region      = var.region
  name        = var.name
  description = "Redshift cluster ${var.name}"
  subnet_ids  = var.subnet_ids

  tags = merge(local.tags, { Name = var.name })
}
