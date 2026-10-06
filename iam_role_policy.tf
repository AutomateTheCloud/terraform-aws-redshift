# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

data "aws_iam_policy_document" "this" {
  count = length(var.iam_role.source_policy_documents) > 0 ? 1 : 0

  source_policy_documents = var.iam_role.source_policy_documents
}

resource "aws_iam_role_policy" "this" {
  count = length(var.iam_role.source_policy_documents) > 0 ? 1 : 0

  name   = "redshift-cluster"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.this[0].json
}
