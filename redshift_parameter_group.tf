# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# The family is part of the name, so that a new family creates a new group first and the
# cluster moves to it before the old one, which the cluster still uses, is deleted. The
# description is fixed for the same reason: changing it replaces the group.
resource "aws_redshift_parameter_group" "this" {
  region      = var.region
  name        = "${var.name}-${replace(var.parameter_group.family, ".", "-")}"
  description = "Redshift cluster ${var.name}"
  family      = var.parameter_group.family

  dynamic "parameter" {
    for_each = local.parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = merge(local.tags, { Name = var.name })

  lifecycle {
    create_before_destroy = true
  }
}
