# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_redshift_cluster" "this" {
  region             = var.region
  cluster_identifier = var.name
  cluster_version    = var.cluster_version
  node_type          = var.node_type
  cluster_type       = var.number_of_nodes > 1 ? "multi-node" : "single-node"
  number_of_nodes    = var.number_of_nodes
  multi_az           = var.multi_az

  # Set either way: AWS turns it on for new RA3 clusters, and provider 6.0.0 sends it only
  # when true, so leaving it false let AWS turn it on and the next plan turn it off.
  availability_zone_relocation_enabled = var.availability_zone_relocation
  port                                 = var.port

  # Always encrypted. The argument is a string in the provider.
  encrypted  = "true"
  kms_key_id = var.kms_key_id

  database_name                     = var.database_name
  master_username                   = var.master_username
  master_password                   = var.master_password
  manage_master_password            = local.manage_master_password ? true : null
  master_password_secret_kms_key_id = local.manage_master_password ? var.master_password_secret_kms_key_id : null

  cluster_subnet_group_name    = aws_redshift_subnet_group.this.name
  cluster_parameter_group_name = aws_redshift_parameter_group.this.name
  vpc_security_group_ids       = concat([aws_security_group.this.id], var.security_group_ids)
  publicly_accessible          = var.publicly_accessible
  enhanced_vpc_routing         = var.enhanced_vpc_routing

  iam_roles            = concat([aws_iam_role.this.arn], var.iam_role.additional_role_arns)
  default_iam_role_arn = aws_iam_role.this.arn

  automated_snapshot_retention_period = var.backup.retention_period
  manual_snapshot_retention_period    = var.backup.manual_snapshot_retention_period
  skip_final_snapshot                 = var.skip_final_snapshot
  final_snapshot_identifier           = "${var.name}-final-${random_id.final_snapshot.hex}"
  snapshot_identifier                 = var.snapshot_identifier

  preferred_maintenance_window = var.maintenance.window
  allow_version_upgrade        = var.maintenance.allow_version_upgrade
  maintenance_track_name       = var.maintenance.track_name

  tags = local.tags

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }

  lifecycle {
    # Used only when the cluster is created. A restore from a snapshot gets these from
    # the snapshot, and changing them would replace the cluster.
    ignore_changes = [
      database_name,
      master_username,
      snapshot_identifier,
    ]
  }
}
