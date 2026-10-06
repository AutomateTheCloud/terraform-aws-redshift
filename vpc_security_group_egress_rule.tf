# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = var.security_group_egress

  region            = var.region
  security_group_id = aws_security_group.this.id
  description       = coalesce(each.value.description, each.key)
  ip_protocol       = "tcp"
  from_port         = each.value.port
  to_port           = each.value.port

  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  referenced_security_group_id = each.value.security_group_id
  prefix_list_id               = each.value.prefix_list_id

  tags = merge(local.tags, { Name = "${var.name}-${each.key}" })
}

# HTTPS to Amazon S3 in the cluster's Region, for COPY and UNLOAD with enhanced VPC routing.
resource "aws_vpc_security_group_egress_rule" "s3" {
  count = var.allow_s3_egress ? 1 : 0

  region            = var.region
  security_group_id = aws_security_group.this.id
  description       = "Amazon S3"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_id    = data.aws_ec2_managed_prefix_list.s3[0].id

  tags = merge(local.tags, { Name = "${var.name}-s3" })
}
