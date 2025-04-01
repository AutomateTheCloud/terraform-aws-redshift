locals {
  alarm = {
    cpu_utilization = {
      critical = try(var.alarm.cpu_utilization.critical, 90)
      warning  = try(var.alarm.cpu_utilization.warning, 80)
    }
    free_storage_space = {
      critical = try(var.alarm.free_storage_space.critical, 90)
      warning  = try(var.alarm.free_storage_space.warning, 80)
    }
  }

  kms_key_id = try(var.encryption.enabled, true) ? try(var.encryption.kms_key_id, "alias/aws/redshift") : null

  parameter_group = {
    name = try(var.parameter_group.existing, null) != null ? var.parameter_group.existing : aws_redshift_parameter_group.this[0].name
  }

  subnet_group = {
    name = try(var.cluster_subnet_group.existing, null) != null ? var.cluster_subnet_group.existing : aws_redshift_subnet_group.this[0].name
  }

  subnet = {
    ids = try(var.cluster_subnet_group.subnet_network_tag, "") != "" ? distinct(compact(concat(tolist(data.aws_subnets.this[0].ids), try(var.cluster_subnet_group.subnets, [])))) : var.cluster_subnet_group.subnets
  }

  master_password = try(var.credentials.master.password, null) != null ? var.credentials.master.password : random_password.master_password.result
}
