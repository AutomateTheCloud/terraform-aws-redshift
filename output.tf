output "metadata" {
  description = "Metadata"
  value = {
    details = {
      scope = {
        name    = local.scope.name
        abbr    = local.scope.abbr
        machine = local.scope.machine
      }
      purpose = {
        name    = local.purpose.name
        abbr    = local.purpose.abbr
        machine = local.purpose.machine
      }
      environment = {
        name    = local.environment.name
        abbr    = local.environment.abbr
        machine = local.environment.machine
      }
      tags = local.tags
    }

    aws = {
      account = {
        id = local.aws.account.id
      }
      region = {
        name        = local.aws.region.name
        abbr        = local.aws.region.abbr
        description = local.aws.region.description
      }
    }

    iam = {
      role = try(aws_iam_role.this, null)
    }

    redshift = {
      cluster = {
        allow_version_upgrade               = try(aws_redshift_cluster.this.allow_version_upgrade, null)
        apply_immediately                   = try(aws_redshift_cluster.this.apply_immediately, null)
        arn                                 = try(aws_redshift_cluster.this.arn, null)
        automated_snapshot_retention_period = try(aws_redshift_cluster.this.automated_snapshot_retention_period, null)
        availability_zone                   = try(aws_redshift_cluster.this.availability_zone, null)
        cluster_identifier                  = try(aws_redshift_cluster.this.cluster_identifier, null)
        cluster_nodes                       = try(aws_redshift_cluster.this.cluster_nodes, null)
        cluster_parameter_group_name        = try(aws_redshift_cluster.this.cluster_parameter_group_name, null)
        cluster_public_key                  = try(aws_redshift_cluster.this.cluster_public_key, null)
        cluster_revision_number             = try(aws_redshift_cluster.this.cluster_revision_number, null)
        cluster_subnet_group_name           = try(aws_redshift_cluster.this.cluster_subnet_group_name, null)
        cluster_type                        = try(aws_redshift_cluster.this.cluster_type, null)
        cluster_version                     = try(aws_redshift_cluster.this.cluster_version, null)
        database_name                       = try(aws_redshift_cluster.this.database_name, null)
        default_iam_role_arn                = try(aws_redshift_cluster.this.default_iam_role_arn, null)
        dns_name                            = try(aws_redshift_cluster.this.dns_name, null)
        encrypted                           = try(aws_redshift_cluster.this.encrypted, null)
        endpoint                            = try(aws_redshift_cluster.this.endpoint, null)
        enhanced_vpc_routing                = try(aws_redshift_cluster.this.enhanced_vpc_routing, null)
        final_snapshot_identifier           = try(aws_redshift_cluster.this.final_snapshot_identifier, null)
        iam_roles                           = try(aws_redshift_cluster.this.iam_roles, null)
        id                                  = try(aws_redshift_cluster.this.id, null)
        kms_key_id                          = try(aws_redshift_cluster.this.kms_key_id, null)
        maintenance_track_name              = try(aws_redshift_cluster.this.maintenance_track_name, null)
        manual_snapshot_retention_period    = try(aws_redshift_cluster.this.manual_snapshot_retention_period, null)
        master_username                     = try(aws_redshift_cluster.this.master_username, null)
        node_type                           = try(aws_redshift_cluster.this.node_type, null)
        number_of_nodes                     = try(aws_redshift_cluster.this.number_of_nodes, null)
        port                                = try(aws_redshift_cluster.this.port, null)
        preferred_maintenance_window        = try(aws_redshift_cluster.this.preferred_maintenance_window, null)
        publicly_accessible                 = try(aws_redshift_cluster.this.publicly_accessible, null)
        skip_final_snapshot                 = try(aws_redshift_cluster.this.skip_final_snapshot, null)
        snapshot_identifier                 = try(aws_redshift_cluster.this.snapshot_identifier, null)
        tags                                = try(aws_redshift_cluster.this.tags, null)
        tags_all                            = try(aws_redshift_cluster.this.tags_all, null)
        vpc_security_group_ids              = try(aws_redshift_cluster.this.vpc_security_group_ids, null)
        logging                             = try(aws_redshift_cluster.this.logging, null)
        timeouts                            = try(aws_redshift_cluster.this.timeouts, null)
      }
      parameter_group   = try(aws_redshift_parameter_group.this[0], null)
      snapshot_schedule = try(aws_redshift_snapshot_schedule.this, null)
      subnet_group      = try(aws_redshift_subnet_group.this[0], null)
    }

    security_group = try(aws_security_group.this, null)

    sns = {
      topic = {
        critical = try(aws_sns_topic.critical, null)
        warning  = try(aws_sns_topic.warning, null)
      }
    }
  }
}
