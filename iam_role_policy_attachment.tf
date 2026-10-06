# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_iam_role_policy_attachment" "this" {
  for_each = var.iam_role.managed_policy_arns

  role       = aws_iam_role.this.name
  policy_arn = each.value
}
