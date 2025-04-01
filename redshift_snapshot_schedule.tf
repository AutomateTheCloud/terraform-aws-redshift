resource "aws_redshift_snapshot_schedule" "this" {
  count       = try(var.backup.schedule, null) != null ? 1 : 0
  identifier  = var.name
  description = var.name
  definitions = [var.backup.schedule]
  tags        = local.tags
  provider    = aws.this
}
