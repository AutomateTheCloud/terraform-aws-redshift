# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

output "metadata" {
  description = <<-EOT
    Everything the module created, in one object, so that other configurations need only one reference:

    - `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
    - `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`.
    - `redshift_cluster` - The cluster's `id`, `arn`, `endpoint` (`<dns_name>:<port>`), `dns_name`, `port`, `database_name`, `master_username`, `master_password_secret_arn` (the Secrets Manager secret, when Amazon Redshift keeps the password), `default_iam_role_arn`, `kms_key_id`, `cluster_namespace_arn` and the rest of its attributes. The nodes' addresses are left out, because they change with every resize; `aws redshift describe-clusters` lists them.
    - `redshift_subnet_group` - The cluster subnet group, with its `name` and `subnet_ids`.
    - `redshift_parameter_group` - The cluster parameter group, with its `name`, `family` and `parameter` values.
    - `redshift_snapshot_schedule` - The snapshot schedule, with its `identifier` and `definitions`, or `null` without `backup.schedules`.
    - `redshift_snapshot_schedule_association` - The schedule's attachment to the cluster, or `null`.
    - `redshift_logging` - The audit logging settings, or `null` when `logging.destination` is not set.
    - `iam_role` - The cluster's IAM role, with its `name` and `arn`.
    - `iam_role_policy` - The role's inline policy from `iam_role.source_policy_documents`, or `null` when there are none.
    - `iam_role_policy_attachment` - The managed policies attached to the role, keyed like `iam_role.managed_policy_arns`, or `null` when there are none.
    - `security_group` - The cluster's security group, with its `id`, `arn` and `name`. Use its `id` as a source in other groups' rules.
    - `vpc_security_group_ingress_rule` - The ingress rules, keyed like `security_group_ingress`, or `null` when there are none.
    - `vpc_security_group_egress_rule` - The egress rules, keyed like `security_group_egress`, or `null` when there are none.
    - `vpc_security_group_egress_rule_s3` - The egress rule to Amazon S3, or `null` when `allow_s3_egress` is `false`.
    - `cloudwatch_log_group` - The audit log groups, keyed by log, each with its `name` and `arn`, or `null` when logs do not go to CloudWatch Logs.
    - `sns_topic` - The alarm topics, keyed `critical` and `warning`, each with its `arn` and `name`, or `null` when `alarms.enabled` is `false`. Subscribe to them to receive the alarms.
    - `sns_topic_policy` - The topics' access policies, keyed like `sns_topic`, or `null`.
    - `cloudwatch_metric_alarm` - The alarms, keyed `health-critical`, `cpu-critical`, `cpu-warning`, `disk-critical` and `disk-warning`, each with its `alarm_name`, `arn` and `threshold`, or `null` when `alarms.enabled` is `false`.
  EOT
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

    redshift_cluster = {
      allow_version_upgrade                = aws_redshift_cluster.this.allow_version_upgrade
      arn                                  = aws_redshift_cluster.this.arn
      automated_snapshot_retention_period  = aws_redshift_cluster.this.automated_snapshot_retention_period
      availability_zone                    = aws_redshift_cluster.this.availability_zone
      availability_zone_relocation_enabled = aws_redshift_cluster.this.availability_zone_relocation_enabled
      cluster_identifier                   = aws_redshift_cluster.this.cluster_identifier
      cluster_namespace_arn                = aws_redshift_cluster.this.cluster_namespace_arn
      cluster_parameter_group_name         = aws_redshift_cluster.this.cluster_parameter_group_name
      cluster_public_key                   = aws_redshift_cluster.this.cluster_public_key
      cluster_revision_number              = aws_redshift_cluster.this.cluster_revision_number
      cluster_subnet_group_name            = aws_redshift_cluster.this.cluster_subnet_group_name
      cluster_type                         = aws_redshift_cluster.this.cluster_type
      cluster_version                      = aws_redshift_cluster.this.cluster_version
      database_name                        = aws_redshift_cluster.this.database_name
      default_iam_role_arn                 = aws_redshift_cluster.this.default_iam_role_arn
      dns_name                             = aws_redshift_cluster.this.dns_name
      encrypted                            = aws_redshift_cluster.this.encrypted
      endpoint                             = aws_redshift_cluster.this.endpoint
      enhanced_vpc_routing                 = aws_redshift_cluster.this.enhanced_vpc_routing
      final_snapshot_identifier            = aws_redshift_cluster.this.final_snapshot_identifier
      iam_roles                            = aws_redshift_cluster.this.iam_roles
      id                                   = aws_redshift_cluster.this.id
      kms_key_id                           = aws_redshift_cluster.this.kms_key_id
      maintenance_track_name               = aws_redshift_cluster.this.maintenance_track_name
      manage_master_password               = aws_redshift_cluster.this.manage_master_password
      manual_snapshot_retention_period     = aws_redshift_cluster.this.manual_snapshot_retention_period
      master_password_secret_arn           = aws_redshift_cluster.this.master_password_secret_arn
      master_password_secret_kms_key_id    = aws_redshift_cluster.this.master_password_secret_kms_key_id
      master_username                      = aws_redshift_cluster.this.master_username
      multi_az                             = aws_redshift_cluster.this.multi_az
      node_type                            = aws_redshift_cluster.this.node_type
      number_of_nodes                      = aws_redshift_cluster.this.number_of_nodes
      port                                 = aws_redshift_cluster.this.port
      preferred_maintenance_window         = aws_redshift_cluster.this.preferred_maintenance_window
      publicly_accessible                  = aws_redshift_cluster.this.publicly_accessible
      region                               = aws_redshift_cluster.this.region
      skip_final_snapshot                  = aws_redshift_cluster.this.skip_final_snapshot
      snapshot_identifier                  = aws_redshift_cluster.this.snapshot_identifier
      tags                                 = aws_redshift_cluster.this.tags
      tags_all                             = aws_redshift_cluster.this.tags_all
      vpc_security_group_ids               = aws_redshift_cluster.this.vpc_security_group_ids
    }

    redshift_subnet_group = {
      arn         = aws_redshift_subnet_group.this.arn
      description = aws_redshift_subnet_group.this.description
      id          = aws_redshift_subnet_group.this.id
      name        = aws_redshift_subnet_group.this.name
      region      = aws_redshift_subnet_group.this.region
      subnet_ids  = aws_redshift_subnet_group.this.subnet_ids
      tags        = aws_redshift_subnet_group.this.tags
      tags_all    = aws_redshift_subnet_group.this.tags_all
    }

    redshift_parameter_group = {
      arn         = aws_redshift_parameter_group.this.arn
      description = aws_redshift_parameter_group.this.description
      family      = aws_redshift_parameter_group.this.family
      id          = aws_redshift_parameter_group.this.id
      name        = aws_redshift_parameter_group.this.name
      parameter   = aws_redshift_parameter_group.this.parameter
      region      = aws_redshift_parameter_group.this.region
      tags        = aws_redshift_parameter_group.this.tags
      tags_all    = aws_redshift_parameter_group.this.tags_all
    }

    redshift_snapshot_schedule = length(aws_redshift_snapshot_schedule.this) == 0 ? null : {
      arn               = aws_redshift_snapshot_schedule.this[0].arn
      definitions       = aws_redshift_snapshot_schedule.this[0].definitions
      description       = aws_redshift_snapshot_schedule.this[0].description
      force_destroy     = aws_redshift_snapshot_schedule.this[0].force_destroy
      id                = aws_redshift_snapshot_schedule.this[0].id
      identifier        = aws_redshift_snapshot_schedule.this[0].identifier
      identifier_prefix = aws_redshift_snapshot_schedule.this[0].identifier_prefix
      region            = aws_redshift_snapshot_schedule.this[0].region
      tags              = aws_redshift_snapshot_schedule.this[0].tags
      tags_all          = aws_redshift_snapshot_schedule.this[0].tags_all
    }

    redshift_snapshot_schedule_association = length(aws_redshift_snapshot_schedule_association.this) == 0 ? null : {
      cluster_identifier  = aws_redshift_snapshot_schedule_association.this[0].cluster_identifier
      id                  = aws_redshift_snapshot_schedule_association.this[0].id
      region              = aws_redshift_snapshot_schedule_association.this[0].region
      schedule_identifier = aws_redshift_snapshot_schedule_association.this[0].schedule_identifier
    }

    redshift_logging = length(aws_redshift_logging.this) == 0 ? null : {
      bucket_name          = aws_redshift_logging.this[0].bucket_name
      cluster_identifier   = aws_redshift_logging.this[0].cluster_identifier
      log_destination_type = aws_redshift_logging.this[0].log_destination_type
      log_exports          = aws_redshift_logging.this[0].log_exports
      region               = aws_redshift_logging.this[0].region
      s3_key_prefix        = aws_redshift_logging.this[0].s3_key_prefix
    }

    iam_role = {
      arn                   = aws_iam_role.this.arn
      assume_role_policy    = aws_iam_role.this.assume_role_policy
      create_date           = aws_iam_role.this.create_date
      description           = aws_iam_role.this.description
      force_detach_policies = aws_iam_role.this.force_detach_policies
      id                    = aws_iam_role.this.id
      max_session_duration  = aws_iam_role.this.max_session_duration
      name                  = aws_iam_role.this.name
      name_prefix           = aws_iam_role.this.name_prefix
      path                  = aws_iam_role.this.path
      permissions_boundary  = aws_iam_role.this.permissions_boundary
      tags                  = aws_iam_role.this.tags
      tags_all              = aws_iam_role.this.tags_all
      unique_id             = aws_iam_role.this.unique_id
    }

    iam_role_policy = length(aws_iam_role_policy.this) == 0 ? null : {
      id          = aws_iam_role_policy.this[0].id
      name        = aws_iam_role_policy.this[0].name
      name_prefix = aws_iam_role_policy.this[0].name_prefix
      policy      = aws_iam_role_policy.this[0].policy
      role        = aws_iam_role_policy.this[0].role
    }

    iam_role_policy_attachment = length(var.iam_role.managed_policy_arns) == 0 ? null : {
      for k in keys(var.iam_role.managed_policy_arns) : k => {
        id         = aws_iam_role_policy_attachment.this[k].id
        policy_arn = aws_iam_role_policy_attachment.this[k].policy_arn
        role       = aws_iam_role_policy_attachment.this[k].role
      }
    }

    security_group = {
      arn                    = aws_security_group.this.arn
      description            = aws_security_group.this.description
      id                     = aws_security_group.this.id
      name                   = aws_security_group.this.name
      name_prefix            = aws_security_group.this.name_prefix
      owner_id               = aws_security_group.this.owner_id
      region                 = aws_security_group.this.region
      revoke_rules_on_delete = aws_security_group.this.revoke_rules_on_delete
      tags                   = aws_security_group.this.tags
      tags_all               = aws_security_group.this.tags_all
      vpc_id                 = aws_security_group.this.vpc_id
    }

    vpc_security_group_ingress_rule = length(var.security_group_ingress) == 0 ? null : {
      for k in keys(var.security_group_ingress) : k => {
        arn                          = aws_vpc_security_group_ingress_rule.this[k].arn
        cidr_ipv4                    = aws_vpc_security_group_ingress_rule.this[k].cidr_ipv4
        cidr_ipv6                    = aws_vpc_security_group_ingress_rule.this[k].cidr_ipv6
        description                  = aws_vpc_security_group_ingress_rule.this[k].description
        from_port                    = aws_vpc_security_group_ingress_rule.this[k].from_port
        id                           = aws_vpc_security_group_ingress_rule.this[k].id
        ip_protocol                  = aws_vpc_security_group_ingress_rule.this[k].ip_protocol
        prefix_list_id               = aws_vpc_security_group_ingress_rule.this[k].prefix_list_id
        referenced_security_group_id = aws_vpc_security_group_ingress_rule.this[k].referenced_security_group_id
        region                       = aws_vpc_security_group_ingress_rule.this[k].region
        security_group_id            = aws_vpc_security_group_ingress_rule.this[k].security_group_id
        security_group_rule_id       = aws_vpc_security_group_ingress_rule.this[k].security_group_rule_id
        tags                         = aws_vpc_security_group_ingress_rule.this[k].tags
        tags_all                     = aws_vpc_security_group_ingress_rule.this[k].tags_all
        to_port                      = aws_vpc_security_group_ingress_rule.this[k].to_port
      }
    }

    vpc_security_group_egress_rule = length(var.security_group_egress) == 0 ? null : {
      for k in keys(var.security_group_egress) : k => {
        arn                          = aws_vpc_security_group_egress_rule.this[k].arn
        cidr_ipv4                    = aws_vpc_security_group_egress_rule.this[k].cidr_ipv4
        cidr_ipv6                    = aws_vpc_security_group_egress_rule.this[k].cidr_ipv6
        description                  = aws_vpc_security_group_egress_rule.this[k].description
        from_port                    = aws_vpc_security_group_egress_rule.this[k].from_port
        id                           = aws_vpc_security_group_egress_rule.this[k].id
        ip_protocol                  = aws_vpc_security_group_egress_rule.this[k].ip_protocol
        prefix_list_id               = aws_vpc_security_group_egress_rule.this[k].prefix_list_id
        referenced_security_group_id = aws_vpc_security_group_egress_rule.this[k].referenced_security_group_id
        region                       = aws_vpc_security_group_egress_rule.this[k].region
        security_group_id            = aws_vpc_security_group_egress_rule.this[k].security_group_id
        security_group_rule_id       = aws_vpc_security_group_egress_rule.this[k].security_group_rule_id
        tags                         = aws_vpc_security_group_egress_rule.this[k].tags
        tags_all                     = aws_vpc_security_group_egress_rule.this[k].tags_all
        to_port                      = aws_vpc_security_group_egress_rule.this[k].to_port
      }
    }

    vpc_security_group_egress_rule_s3 = length(aws_vpc_security_group_egress_rule.s3) == 0 ? null : {
      arn                          = aws_vpc_security_group_egress_rule.s3[0].arn
      cidr_ipv4                    = aws_vpc_security_group_egress_rule.s3[0].cidr_ipv4
      cidr_ipv6                    = aws_vpc_security_group_egress_rule.s3[0].cidr_ipv6
      description                  = aws_vpc_security_group_egress_rule.s3[0].description
      from_port                    = aws_vpc_security_group_egress_rule.s3[0].from_port
      id                           = aws_vpc_security_group_egress_rule.s3[0].id
      ip_protocol                  = aws_vpc_security_group_egress_rule.s3[0].ip_protocol
      prefix_list_id               = aws_vpc_security_group_egress_rule.s3[0].prefix_list_id
      referenced_security_group_id = aws_vpc_security_group_egress_rule.s3[0].referenced_security_group_id
      region                       = aws_vpc_security_group_egress_rule.s3[0].region
      security_group_id            = aws_vpc_security_group_egress_rule.s3[0].security_group_id
      security_group_rule_id       = aws_vpc_security_group_egress_rule.s3[0].security_group_rule_id
      tags                         = aws_vpc_security_group_egress_rule.s3[0].tags
      tags_all                     = aws_vpc_security_group_egress_rule.s3[0].tags_all
      to_port                      = aws_vpc_security_group_egress_rule.s3[0].to_port
    }

    cloudwatch_log_group = length(local.cloudwatch_log_groups) == 0 ? null : {
      for k in local.cloudwatch_log_groups : k => {
        arn               = aws_cloudwatch_log_group.this[k].arn
        id                = aws_cloudwatch_log_group.this[k].id
        kms_key_id        = aws_cloudwatch_log_group.this[k].kms_key_id
        log_group_class   = aws_cloudwatch_log_group.this[k].log_group_class
        name              = aws_cloudwatch_log_group.this[k].name
        name_prefix       = aws_cloudwatch_log_group.this[k].name_prefix
        region            = aws_cloudwatch_log_group.this[k].region
        retention_in_days = aws_cloudwatch_log_group.this[k].retention_in_days
        skip_destroy      = aws_cloudwatch_log_group.this[k].skip_destroy
        tags              = aws_cloudwatch_log_group.this[k].tags
        tags_all          = aws_cloudwatch_log_group.this[k].tags_all
      }
    }

    sns_topic = length(local.sns_topics) == 0 ? null : {
      for k in local.sns_topics : k => {
        application_failure_feedback_role_arn    = aws_sns_topic.this[k].application_failure_feedback_role_arn
        application_success_feedback_role_arn    = aws_sns_topic.this[k].application_success_feedback_role_arn
        application_success_feedback_sample_rate = aws_sns_topic.this[k].application_success_feedback_sample_rate
        archive_policy                           = aws_sns_topic.this[k].archive_policy
        arn                                      = aws_sns_topic.this[k].arn
        beginning_archive_time                   = aws_sns_topic.this[k].beginning_archive_time
        content_based_deduplication              = aws_sns_topic.this[k].content_based_deduplication
        delivery_policy                          = aws_sns_topic.this[k].delivery_policy
        display_name                             = aws_sns_topic.this[k].display_name
        fifo_throughput_scope                    = aws_sns_topic.this[k].fifo_throughput_scope
        fifo_topic                               = aws_sns_topic.this[k].fifo_topic
        firehose_failure_feedback_role_arn       = aws_sns_topic.this[k].firehose_failure_feedback_role_arn
        firehose_success_feedback_role_arn       = aws_sns_topic.this[k].firehose_success_feedback_role_arn
        firehose_success_feedback_sample_rate    = aws_sns_topic.this[k].firehose_success_feedback_sample_rate
        http_failure_feedback_role_arn           = aws_sns_topic.this[k].http_failure_feedback_role_arn
        http_success_feedback_role_arn           = aws_sns_topic.this[k].http_success_feedback_role_arn
        http_success_feedback_sample_rate        = aws_sns_topic.this[k].http_success_feedback_sample_rate
        id                                       = aws_sns_topic.this[k].id
        kms_master_key_id                        = aws_sns_topic.this[k].kms_master_key_id
        lambda_failure_feedback_role_arn         = aws_sns_topic.this[k].lambda_failure_feedback_role_arn
        lambda_success_feedback_role_arn         = aws_sns_topic.this[k].lambda_success_feedback_role_arn
        lambda_success_feedback_sample_rate      = aws_sns_topic.this[k].lambda_success_feedback_sample_rate
        name                                     = aws_sns_topic.this[k].name
        name_prefix                              = aws_sns_topic.this[k].name_prefix
        owner                                    = aws_sns_topic.this[k].owner
        region                                   = aws_sns_topic.this[k].region
        signature_version                        = aws_sns_topic.this[k].signature_version
        sqs_failure_feedback_role_arn            = aws_sns_topic.this[k].sqs_failure_feedback_role_arn
        sqs_success_feedback_role_arn            = aws_sns_topic.this[k].sqs_success_feedback_role_arn
        sqs_success_feedback_sample_rate         = aws_sns_topic.this[k].sqs_success_feedback_sample_rate
        tags                                     = aws_sns_topic.this[k].tags
        tags_all                                 = aws_sns_topic.this[k].tags_all
        tracing_config                           = aws_sns_topic.this[k].tracing_config
      }
    }

    sns_topic_policy = length(local.sns_topics) == 0 ? null : {
      for k in local.sns_topics : k => {
        arn    = aws_sns_topic_policy.this[k].arn
        id     = aws_sns_topic_policy.this[k].id
        owner  = aws_sns_topic_policy.this[k].owner
        policy = aws_sns_topic_policy.this[k].policy
        region = aws_sns_topic_policy.this[k].region
      }
    }

    cloudwatch_metric_alarm = length(local.alarms) == 0 ? null : {
      for k in keys(local.alarms) : k => {
        actions_enabled                       = aws_cloudwatch_metric_alarm.this[k].actions_enabled
        alarm_actions                         = aws_cloudwatch_metric_alarm.this[k].alarm_actions
        alarm_description                     = aws_cloudwatch_metric_alarm.this[k].alarm_description
        alarm_name                            = aws_cloudwatch_metric_alarm.this[k].alarm_name
        arn                                   = aws_cloudwatch_metric_alarm.this[k].arn
        comparison_operator                   = aws_cloudwatch_metric_alarm.this[k].comparison_operator
        datapoints_to_alarm                   = aws_cloudwatch_metric_alarm.this[k].datapoints_to_alarm
        dimensions                            = aws_cloudwatch_metric_alarm.this[k].dimensions
        evaluate_low_sample_count_percentiles = aws_cloudwatch_metric_alarm.this[k].evaluate_low_sample_count_percentiles
        evaluation_periods                    = aws_cloudwatch_metric_alarm.this[k].evaluation_periods
        extended_statistic                    = aws_cloudwatch_metric_alarm.this[k].extended_statistic
        id                                    = aws_cloudwatch_metric_alarm.this[k].id
        metric_name                           = aws_cloudwatch_metric_alarm.this[k].metric_name
        metric_query                          = aws_cloudwatch_metric_alarm.this[k].metric_query
        namespace                             = aws_cloudwatch_metric_alarm.this[k].namespace
        ok_actions                            = aws_cloudwatch_metric_alarm.this[k].ok_actions
        period                                = aws_cloudwatch_metric_alarm.this[k].period
        region                                = aws_cloudwatch_metric_alarm.this[k].region
        statistic                             = aws_cloudwatch_metric_alarm.this[k].statistic
        tags                                  = aws_cloudwatch_metric_alarm.this[k].tags
        tags_all                              = aws_cloudwatch_metric_alarm.this[k].tags_all
        threshold                             = aws_cloudwatch_metric_alarm.this[k].threshold
        threshold_metric_id                   = aws_cloudwatch_metric_alarm.this[k].threshold_metric_id
        treat_missing_data                    = aws_cloudwatch_metric_alarm.this[k].treat_missing_data
        unit                                  = aws_cloudwatch_metric_alarm.this[k].unit
      }
    }
  }
}
