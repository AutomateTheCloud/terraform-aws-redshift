data "aws_kms_key" "redshift" {
  count    = try(local.kms_key_id, null) != null ? 1 : 0
  key_id   = local.kms_key_id
  provider = aws.this
}

data "aws_vpc" "this" {
  id       = var.vpc_id
  provider = aws.this
}

data "aws_subnets" "this" {
  count = try(var.cluster_subnet_group.subnet_network_tag, "") != "" ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "tag:Network"
    values = [try(var.cluster_subnet_group.subnet_network_tag, "")]
  }
  provider = aws.this
}
