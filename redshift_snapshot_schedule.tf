# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_redshift_snapshot_schedule" "this" {
  count = length(var.backup.schedules) > 0 ? 1 : 0

  region      = var.region
  identifier  = var.name
  description = "Redshift cluster ${var.name}"
  definitions = var.backup.schedules

  tags = local.tags
}
