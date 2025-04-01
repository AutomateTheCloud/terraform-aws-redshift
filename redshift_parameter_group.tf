resource "aws_redshift_parameter_group" "this" {
  count       = try(var.parameter_group.existing, null) != null ? 0 : 1
  name        = var.name
  description = "${local.scope.name} - ${local.purpose.name} (${local.environment.abbr}) [${local.aws.region.name}]: ${var.name}"
  family      = try(var.parameter_group.family, null)

  dynamic "parameter" {
    for_each = try(var.parameter_group.parameter, [])
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }
  dynamic "parameter" {
    for_each = try(var.parameter_group.wlm_configuration_json_file, null) != null ? [1] : []
    content {
      name = "wlm_json_configuration"
      # When encoding strings, this function escapes some characters using Unicode escape sequences: replacing <, >, &, U+2028, and U+2029 with \u003c, \u003e, \u0026, \u2028, and \u2029. This is to preserve compatibility with Terraform 0.11 behavior
      value = try(replace(replace(jsonencode(jsondecode(file(var.parameter_group.wlm_configuration_json_file))), "\\u003e", ">"), "\\u003c", "<"), null)
    }
  }

  tags = merge(
    local.tags,
    tomap({
      "Name" = var.name
    })
  )
  provider = aws.this
}
