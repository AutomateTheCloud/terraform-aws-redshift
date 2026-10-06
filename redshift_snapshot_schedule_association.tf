# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_redshift_snapshot_schedule_association" "this" {
  count = length(var.backup.schedules) > 0 ? 1 : 0

  region              = var.region
  cluster_identifier  = aws_redshift_cluster.this.id
  schedule_identifier = aws_redshift_snapshot_schedule.this[0].id
}
