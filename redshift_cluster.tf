resource "aws_redshift_cluster" "this" {
  cluster_identifier = var.name
  cluster_version    = var.engine_version
  node_type          = try(var.node.type, null)
  cluster_type       = try(var.node.count, 1) > 1 ? "multi-node" : "single-node"
  number_of_nodes    = try(var.node.count, 1)
  database_name      = var.db_name
  master_username    = try(var.credentials.master.username, null)
  master_password    = local.master_password

  port                 = var.port
  publicly_accessible  = try(var.node.public, false)
  enhanced_vpc_routing = try(var.node.enhanced_vpc_routing, true)

  vpc_security_group_ids       = [aws_security_group.this.id]
  cluster_subnet_group_name    = local.subnet_group.name
  cluster_parameter_group_name = local.parameter_group.name

  snapshot_identifier       = var.snapshot_identifier
  final_snapshot_identifier = "${var.name}-${random_id.snapshot_identifier.hex}-FINAL"

  automated_snapshot_retention_period = try(var.backup.retention_period, null)
  preferred_maintenance_window        = try(var.maintenance.window, null)
  allow_version_upgrade               = try(var.maintenance.allow_version_upgrade, null)
  skip_final_snapshot                 = try(var.maintenance.skip_final_snapshot, null)

  iam_roles = [aws_iam_role.this.arn]

  encrypted  = try(var.encryption.enabled, true)
  kms_key_id = try(data.aws_kms_key.redshift[0].arn, null)

  logging {
    enable        = try(var.logging.enabled, null) != null ? var.logging.enabled : false
    bucket_name   = try(var.logging.bucket_name, null) != null ? var.logging.bucket_name : null
    s3_key_prefix = try(var.logging.s3_key_prefix, null) != null ? var.logging.s3_key_prefix : null
  }

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }

  lifecycle {
    ignore_changes = [
      snapshot_identifier,
      database_name,
      master_username,
      master_password
    ]
  }
  tags     = local.tags
  provider = aws.this
}
