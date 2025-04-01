resource "aws_sns_topic" "critical" {
  name         = "rs-${var.name}-critical"
  display_name = "rs-${var.name}-critical"
  tags = merge(
    local.tags,
    tomap({
      "Name" = "rs-${var.name}-critical"
    })
  )
  provider = aws.this
}

resource "aws_sns_topic_policy" "critical" {
  arn      = aws_sns_topic.critical.arn
  policy   = data.aws_iam_policy_document.sns_topic-critical.json
  provider = aws.this
}

data "aws_iam_policy_document" "sns_topic-critical" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "cloudwatch.amazonaws.com"
      ]
    }
    actions = [
      "sns:Publish",
    ]
    resources = [
      aws_sns_topic.critical.arn
    ]
  }
  provider = aws.this
}

resource "aws_sns_topic" "warning" {
  name         = "rs-${var.name}-warning"
  display_name = "rs-${var.name}-warning"
  tags = merge(
    local.tags,
    tomap({
      "Name" = "rs-${var.name}-warning"
    })
  )
  provider = aws.this
}

resource "aws_sns_topic_policy" "warning" {
  arn      = aws_sns_topic.warning.arn
  policy   = data.aws_iam_policy_document.sns_topic-warning.json
  provider = aws.this
}

data "aws_iam_policy_document" "sns_topic-warning" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "cloudwatch.amazonaws.com"
      ]
    }
    actions = [
      "sns:Publish",
    ]
    resources = [
      aws_sns_topic.warning.arn
    ]
  }
  provider = aws.this
}
