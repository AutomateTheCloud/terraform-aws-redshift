resource "aws_redshift_snapshot_schedule_association" "this" {
  count               = try(var.backup.schedule, null) != null ? 1 : 0
  cluster_identifier  = aws_redshift_cluster.this.id
  schedule_identifier = aws_redshift_snapshot_schedule.this[0].id
  provider            = aws.this
}
