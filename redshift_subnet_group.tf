resource "aws_redshift_subnet_group" "this" {
  count       = try(var.cluster_subnet_group.existing, null) != null ? 0 : 1
  name        = var.name
  description = "${local.scope.name} - ${local.purpose.name} (${local.environment.abbr}) [${local.aws.region.name}]: ${var.name}"
  subnet_ids  = local.subnet.ids

  tags = merge(
    local.tags,
    tomap({
      "Name" = var.name
    })
  )
  provider = aws.this
}
