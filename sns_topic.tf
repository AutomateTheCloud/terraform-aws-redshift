# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# The topics the alarms notify. Subscribe to them to receive the notifications.
resource "aws_sns_topic" "this" {
  for_each = local.sns_topics

  region            = var.region
  name              = "${var.name}-redshift-${each.key}"
  kms_master_key_id = var.alarms.sns_kms_key_id

  tags = merge(local.tags, { Name = "${var.name}-redshift-${each.key}" })
}
