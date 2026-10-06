# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

variable "alarms" {
  description = <<-EOT
    CloudWatch alarms on the cluster's health, CPU use and disk space, and two Amazon SNS topics they notify: `<name>-redshift-critical` and `<name>-redshift-warning`. Subscribe to the topics, for example by email, to receive the notifications; `metadata.sns_topic` gives their ARNs. On by default.

    - `enabled` - (Optional) Create the alarms and topics. Defaults to `true`.
    - `cpu_utilization` - (Optional) Alarm when the average CPU use of the cluster stays above a percentage for 5 minutes: `critical` (Optional, defaults to `90`) and `warning` (Optional, defaults to `80`).
    - `disk_space_used` - (Optional) Alarm when the percentage of disk space used stays at or above a percentage for 30 minutes: `critical` (Optional, defaults to `90`) and `warning` (Optional, defaults to `80`).
    - `sns_kms_key_id` - (Optional) ARN of a KMS key to encrypt the topics with. Its key policy must allow `cloudwatch.amazonaws.com` to use `kms:Decrypt` and `kms:GenerateDataKey*`. Without it, the topics are not encrypted: CloudWatch cannot publish to a topic encrypted with the AWS managed key `aws/sns`.

    The health alarm, on the critical topic, fires when the cluster reports itself unhealthy for 5 minutes in a row. An alarm with no data, for example while the cluster is paused, keeps its last state.
  EOT
  type = object({
    enabled = optional(bool, true)
    cpu_utilization = optional(object({
      critical = optional(number, 90)
      warning  = optional(number, 80)
    }), {})
    disk_space_used = optional(object({
      critical = optional(number, 90)
      warning  = optional(number, 80)
    }), {})
    sns_kms_key_id = optional(string)
  })
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for t in [var.alarms.cpu_utilization, var.alarms.disk_space_used] :
      t.critical > 0 && t.critical <= 100 && t.warning > 0 && t.warning <= t.critical
    ])
    error_message = "alarms: each critical threshold must be a percentage above 0 and at most 100, and each warning threshold above 0 and at most its critical one."
  }

  validation {
    condition     = var.alarms.sns_kms_key_id == null || startswith(coalesce(var.alarms.sns_kms_key_id, "-"), "arn:")
    error_message = "alarms.sns_kms_key_id must be the ARN of a KMS key."
  }
}

variable "allow_s3_egress" {
  description = <<-EOT
    Add an outbound rule to the cluster's security group for HTTPS (port `443`) to Amazon S3 in the cluster's Region, through the Region's S3 prefix list. With `enhanced_vpc_routing` on, the default, `COPY` and `UNLOAD` reach S3 through the VPC and need it, as well as a route to S3, such as an S3 gateway endpoint or a NAT gateway. Defaults to `true`.

    The rule allows S3 only. Add other destinations, such as another Region's S3 or a database for federated queries, in `security_group_egress`.
  EOT
  type        = bool
  default     = true
  nullable    = false
}

variable "availability_zone_relocation" {
  description = <<-EOT
    Let Amazon Redshift move the cluster to another Availability Zone, keeping its endpoint, when its zone has a problem. On by default, as AWS turns it on for new RA3 clusters. It needs `subnet_ids` in at least two Availability Zones: AWS refuses it for a subnet group in one zone, so set it to `false` for a cluster with subnets in one zone. Not with `multi_az`, which keeps the cluster in two zones instead, and not for DC2 node types. Changing it updates the cluster in place.
  EOT
  type        = bool
  default     = true
  nullable    = false

  validation {
    condition     = !var.availability_zone_relocation || length(var.subnet_ids) >= 2
    error_message = "availability_zone_relocation needs subnet_ids in at least two Availability Zones; set it to false for a cluster in one zone."
  }
}

variable "backup" {
  description = <<-EOT
    Snapshots of the cluster.

    - `retention_period` - (Optional) Days to keep automated snapshots, from `1` to `35`. Defaults to `7`.
    - `manual_snapshot_retention_period` - (Optional) Days to keep manual snapshots taken without their own retention, from `1` to `3653`, or `-1` to keep them until you delete them. Defaults to `-1`.
    - `schedules` - (Optional) When to take automated snapshots, as `rate()` or `cron()` expressions, such as `rate(12 hours)` or `cron(0 3 * * ? *)` (UTC). Without them, Amazon Redshift takes one every 8 hours or every 5 GB of changes per node, whichever comes first. With them, the module creates a snapshot schedule named after the cluster and attaches it.
  EOT
  type = object({
    retention_period                 = optional(number, 7)
    manual_snapshot_retention_period = optional(number, -1)
    schedules                        = optional(set(string), [])
  })
  default  = {}
  nullable = false

  validation {
    condition     = var.backup.retention_period >= 1 && var.backup.retention_period <= 35 && floor(var.backup.retention_period) == var.backup.retention_period
    error_message = "backup.retention_period must be a whole number of days from 1 to 35."
  }

  validation {
    condition     = var.backup.manual_snapshot_retention_period == -1 || (var.backup.manual_snapshot_retention_period >= 1 && var.backup.manual_snapshot_retention_period <= 3653 && floor(var.backup.manual_snapshot_retention_period) == var.backup.manual_snapshot_retention_period)
    error_message = "backup.manual_snapshot_retention_period must be -1 or a whole number of days from 1 to 3653."
  }

  validation {
    condition     = alltrue([for s in var.backup.schedules : can(regex("^(rate\\([0-9]+ (hour|hours)\\)|cron\\(.+\\))$", s))])
    error_message = "backup.schedules entries must be rate() or cron() expressions, such as rate(12 hours) or cron(0 3 * * ? *)."
  }
}

variable "cluster_version" {
  description = <<-EOT
    The Amazon Redshift engine version to start the cluster on. `1.0` is the only value AWS accepts; with `maintenance.allow_version_upgrade`, AWS keeps the cluster on the newest release of it.
  EOT
  type        = string
  default     = "1.0"
  nullable    = false
}

variable "database_name" {
  description = <<-EOT
    The name of the first database to create in the cluster, such as `analytics`. Without it, Amazon Redshift creates `dev`. 1 to 64 lowercase letters, digits, underscores and dollar signs, starting with a letter or underscore.

    Used only when the cluster is created: changing it later does nothing. A cluster restored from a snapshot takes its databases from the snapshot.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.database_name == null || can(regex("^[a-z_][a-z0-9_$]{0,63}$", coalesce(var.database_name, "-")))
    error_message = "database_name must be 1 to 64 lowercase letters, digits, underscores and dollar signs, starting with a letter or underscore."
  }
}

variable "details" {
  description = <<-EOT
    Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-redshift#the-details-input) explains why it is required.

    - `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
    - `purpose` - (Required) What the resource is for: `Web Site`.
    - `environment` - (Required) The environment: `Production`.
    - `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
    - `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.
  EOT
  type = object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
  nullable = false

  validation {
    condition     = trimspace(var.details.scope) != ""
    error_message = "Scope not specified."
  }

  validation {
    condition     = trimspace(var.details.purpose) != ""
    error_message = "Purpose not specified."
  }

  validation {
    condition     = trimspace(var.details.environment) != ""
    error_message = "Environment not specified."
  }
}

variable "enhanced_vpc_routing" {
  description = <<-EOT
    Send the cluster's `COPY` and `UNLOAD` traffic to and from Amazon S3 and other services through the VPC, where security groups, network ACLs, VPC endpoints and VPC Flow Logs apply to it. On by default. The VPC then needs a route to S3, such as an S3 gateway endpoint, and the security group an outbound rule (see `allow_s3_egress`). With it off, that traffic goes over the internet, outside the VPC, and AWS gives each node a public IP address for it; the cluster still accepts connections only as `publicly_accessible` allows.
  EOT
  type        = bool
  default     = true
  nullable    = false
}

variable "iam_role" {
  description = <<-EOT
    Permissions for the IAM role the module creates for the cluster. Amazon Redshift uses the role for `COPY`, `UNLOAD`, Redshift Spectrum and other access to AWS services; it is the cluster's default role, so SQL can name it as `IAM_ROLE default`. With the defaults, the role has no permissions.

    - `source_policy_documents` - (Optional) IAM policy documents, as JSON, to give the role, such as the `json` of an `aws_iam_policy_document` that allows reading one S3 bucket. They are combined into one inline policy. Defaults to none.
    - `managed_policy_arns` - (Optional) Managed policies to attach to the role, as a map of names you choose to policy ARNs, such as `{ glue = aws_iam_policy.glue.arn }`. The names only identify each attachment, so a policy created in the same configuration can be used. Defaults to none. Prefer `source_policy_documents` limited to the resources the cluster uses over broad AWS managed policies.
    - `additional_role_arns` - (Optional) ARNs of more IAM roles, created outside the module, to associate with the cluster. Amazon Redshift allows 50 in all, with the module's role. Each must trust `redshift.amazonaws.com`.

    The role's name starts with the cluster's name and ends with a suffix AWS adds, because IAM role names are unique in the account across Regions. Its trust policy lets only Amazon Redshift in this account use it.
  EOT
  type = object({
    source_policy_documents = optional(list(string), [])
    managed_policy_arns     = optional(map(string), {})
    additional_role_arns    = optional(list(string), [])
  })
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for a in concat(values(var.iam_role.managed_policy_arns), var.iam_role.additional_role_arns) : startswith(a, "arn:")])
    error_message = "iam_role.managed_policy_arns and iam_role.additional_role_arns must be ARNs."
  }

  validation {
    condition     = length(var.iam_role.additional_role_arns) <= 49
    error_message = "iam_role.additional_role_arns: Amazon Redshift allows 50 roles per cluster, including the module's own, so at most 49."
  }
}

variable "kms_key_id" {
  description = <<-EOT
    ARN of the AWS Key Management Service (KMS) key that encrypts the cluster's data and snapshots. The cluster is always encrypted; without a key, Amazon Redshift uses a key that AWS owns and manages.

    Choose the key when the cluster is created. AWS refuses to change it later, including setting one on a cluster created without it: the apply fails with `InvalidParameterCombination`. See [Settings fixed at creation](https://github.com/AutomateTheCloud/terraform-aws-redshift#settings-fixed-at-creation).
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_id == null || startswith(coalesce(var.kms_key_id, "-"), "arn:")
    error_message = "kms_key_id must be the ARN of a KMS key, such as arn:aws:kms:us-east-1:123456789012:key/<key id>."
  }
}

variable "logging" {
  description = <<-EOT
    Audit logging: connections, users and the SQL that users run. Off by default.

    - `destination` - (Optional) Where to send the logs: `cloudwatch` for Amazon CloudWatch Logs or `s3` for an Amazon S3 bucket. Without it, nothing is logged.
    - `log_exports` - (Optional) The logs to send: `connectionlog` (connections and disconnections), `userlog` (changes to database users) and `useractivitylog` (each query). Defaults to all three. With `useractivitylog`, the module turns on the `enable_user_activity_logging` parameter, which that log needs. With `s3`, Amazon Redshift always writes `connectionlog` and `userlog`, and this decides only whether it writes `useractivitylog`: AWS accepts a list of logs only for `cloudwatch`.
    - `bucket_name` - (Optional) The bucket for `s3`, in the cluster's Region. Its bucket policy must allow `redshift.amazonaws.com` to use `s3:PutObject` and `s3:GetBucketAcl`. Required with `s3`.
    - `s3_key_prefix` - (Optional) A prefix for the log files' keys in the bucket, such as `redshift/`.
    - `retention_in_days` - (Optional) For `cloudwatch`: days to keep the logs. Defaults to `7`. One of `1`, `3`, `5`, `7`, `14`, `30`, `60`, `90`, `120`, `150`, `180`, `365`, `400`, `545`, `731`, `1096`, `1827`, `2192`, `2557`, `2922`, `3288` or `3653`, or `0` to keep them forever.
    - `kms_key_id` - (Optional) For `cloudwatch`: ARN of a KMS key to encrypt the logs with. Its key policy must allow the CloudWatch Logs service in the cluster's Region. Without it, CloudWatch Logs encrypts them with a key it owns.

    For `cloudwatch`, the module creates a log group for each log, `/aws/redshift/cluster/<name>/<log>`, before logging starts, so that the retention and key apply from the first line.
  EOT
  type = object({
    destination       = optional(string)
    log_exports       = optional(set(string), ["connectionlog", "userlog", "useractivitylog"])
    bucket_name       = optional(string)
    s3_key_prefix     = optional(string)
    retention_in_days = optional(number, 7)
    kms_key_id        = optional(string)
  })
  default  = {}
  nullable = false

  validation {
    condition     = var.logging.destination == null || contains(["cloudwatch", "s3"], coalesce(var.logging.destination, "-"))
    error_message = "logging.destination must be cloudwatch or s3."
  }

  validation {
    condition     = length(var.logging.log_exports) > 0 && alltrue([for l in var.logging.log_exports : contains(["connectionlog", "userlog", "useractivitylog"], l)])
    error_message = "logging.log_exports must name one or more of connectionlog, userlog and useractivitylog."
  }

  validation {
    condition     = (var.logging.destination == "s3") == (var.logging.bucket_name != null)
    error_message = "logging.bucket_name is required with destination = \"s3\", and used only with it."
  }

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.logging.retention_in_days)
    error_message = "logging.retention_in_days must be 0 (forever) or one of 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653."
  }

  validation {
    condition     = var.logging.kms_key_id == null || startswith(coalesce(var.logging.kms_key_id, "-"), "arn:")
    error_message = "logging.kms_key_id must be the ARN of a KMS key."
  }
}

variable "maintenance" {
  description = <<-EOT
    When and how AWS updates the cluster.

    - `window` - (Optional) The weekly time range, in UTC, for maintenance, such as `sun:05:00-sun:05:30`. At least 30 minutes. Without it, AWS picks one.
    - `allow_version_upgrade` - (Optional) Let AWS upgrade the cluster to new releases of the engine in the maintenance window. Defaults to `true`.
    - `track_name` - (Optional) Which releases to follow: `current` for the newest, or `trailing` for the one before it. Defaults to `current`.
  EOT
  type = object({
    window                = optional(string)
    allow_version_upgrade = optional(bool, true)
    track_name            = optional(string, "current")
  })
  default  = {}
  nullable = false

  validation {
    condition     = var.maintenance.window == null || can(regex("^(mon|tue|wed|thu|fri|sat|sun):([01][0-9]|2[0-3]):[0-5][0-9]-(mon|tue|wed|thu|fri|sat|sun):([01][0-9]|2[0-3]):[0-5][0-9]$", coalesce(var.maintenance.window, "-")))
    error_message = "maintenance.window must be a weekly UTC time range such as sun:05:00-sun:05:30 (lowercase day names)."
  }

  validation {
    condition     = contains(["current", "trailing"], var.maintenance.track_name)
    error_message = "maintenance.track_name must be current or trailing."
  }
}

variable "master_password" {
  description = <<-EOT
    The master user's password. Without it, the default, Amazon Redshift generates the password and keeps it in AWS Secrets Manager, and it is never stored in Terraform state; `metadata.redshift_cluster.master_password_secret_arn` gives the secret's ARN.

    A password given here is stored in Terraform state in plain text. Use it only when the password must come from somewhere else. 8 to 64 printable ASCII characters, with at least one uppercase letter, one lowercase letter and one digit, and no `/`, `@`, `"`, `'`, `\` or spaces. Changing it, or setting it later, updates the cluster in place. Removing it again fails in Terraform alone; see [The master password](https://github.com/AutomateTheCloud/terraform-aws-redshift#the-master-password).
  EOT
  type        = string
  default     = null
  sensitive   = true
}

variable "master_password_secret_kms_key_id" {
  description = <<-EOT
    ARN of a KMS key to encrypt the Secrets Manager secret that holds the master password. Without it, Secrets Manager uses the AWS managed key `aws/secretsmanager`. Not used with `master_password`.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.master_password_secret_kms_key_id == null || startswith(coalesce(var.master_password_secret_kms_key_id, "-"), "arn:")
    error_message = "master_password_secret_kms_key_id must be the ARN of a KMS key."
  }

  validation {
    condition     = var.master_password_secret_kms_key_id == null || var.master_password == null
    error_message = "master_password_secret_kms_key_id applies only to a password kept in Secrets Manager; leave it unset with master_password."
  }
}

variable "master_username" {
  description = <<-EOT
    The name of the master user, the first database user, which can create other users. Defaults to `awsuser`. 1 to 128 lowercase letters, digits, underscores, plus signs, periods, at signs and hyphens, starting with a letter, and not `public`.

    Used only when the cluster is created: changing it later does nothing. A cluster restored from a snapshot takes the master user from the snapshot.
  EOT
  type        = string
  default     = "awsuser"
  nullable    = false

  validation {
    condition     = can(regex("^[a-z][a-z0-9_+.@-]{0,127}$", var.master_username)) && var.master_username != "public"
    error_message = "master_username must be 1 to 128 lowercase letters, digits, _, +, ., @ and -, starting with a letter, and not public."
  }
}

variable "multi_az" {
  description = <<-EOT
    Run the cluster in two Availability Zones, with compute in each, so that it keeps working when one zone fails. Not for DC2 node types, and doubles the compute cost. The subnets in `subnet_ids` must cover at least two zones. Needs `availability_zone_relocation = false`. Defaults to `false`.
  EOT
  type        = bool
  default     = false
  nullable    = false

  validation {
    condition     = !var.multi_az || !startswith(var.node_type, "dc2.")
    error_message = "multi_az does not work with DC2 node types; use a type such as ra3.xlplus."
  }

  validation {
    condition     = !(var.multi_az && var.availability_zone_relocation)
    error_message = "multi_az needs availability_zone_relocation = false: a cluster cannot use both."
  }
}

variable "name" {
  description = <<-EOT
    The cluster identifier, such as `analytics`, unique among your clusters in the Region. The subnet group, parameter group, snapshot schedule, alarms and topics are named after it. 1 to 63 lowercase letters, digits and hyphens, starting with a letter, with no two hyphens in a row and no hyphen at the end.

    Changing it replaces the cluster: Terraform deletes it, taking a final snapshot unless `skip_final_snapshot` is `true`, and creates an empty one.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z]([a-z0-9]|-[a-z0-9])*$", var.name)) && length(var.name) <= 63
    error_message = "name must be 1 to 63 lowercase letters, digits and hyphens, starting with a letter, with no two hyphens in a row and no hyphen at the end."
  }
}

variable "node_type" {
  description = <<-EOT
    The node type, such as `ra3.large`, `ra3.xlplus` or `rg.large`. Not every type is offered in every Region: `aws redshift describe-orderable-cluster-options` lists them. Changing it resizes the cluster in place, which can take a long time on a large cluster.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]+\\.[a-z0-9]+$", var.node_type))
    error_message = "node_type must be a node type such as ra3.large."
  }
}

variable "number_of_nodes" {
  description = <<-EOT
    How many compute nodes the cluster has. `1` makes a single-node cluster; more make a multi-node cluster, which also has a leader node at no charge. Defaults to `1`. The most allowed depends on the node type. Changing it resizes the cluster in place.
  EOT
  type        = number
  default     = 1
  nullable    = false

  validation {
    condition     = var.number_of_nodes >= 1 && var.number_of_nodes <= 128 && floor(var.number_of_nodes) == var.number_of_nodes
    error_message = "number_of_nodes must be a whole number from 1 to 128."
  }
}

variable "parameter_group" {
  description = <<-EOT
    The cluster parameter group the module creates for the cluster, named `<name>-<family>`.

    - `family` - (Optional) The parameter group family. Defaults to `redshift-2.0`.
    - `parameters` - (Optional) Parameters to set, by name, such as `{ max_concurrency_scaling_clusters = "2" }`. Values are strings; give `wlm_json_configuration` as `jsonencode(...)`. Parameters left out keep the family's defaults.

    The module sets `require_ssl` to `true`, so clients must connect with Transport Layer Security (TLS). Set it to `"false"` here only for clients that cannot. It also sets `enable_user_activity_logging`, to `true` when `logging` sends `useractivitylog`, and `false` otherwise. Some parameters take effect only after the cluster restarts.

    Removing a parameter from `parameters` later does not reset it: AWS keeps the value, and every plan tries to remove it again. Set it to the family's default value instead (`aws redshift describe-default-cluster-parameters --parameter-group-family redshift-2.0` lists them).
  EOT
  type = object({
    family     = optional(string, "redshift-2.0")
    parameters = optional(map(string), {})
  })
  default  = {}
  nullable = false

  validation {
    condition     = can(regex("^redshift-[0-9]+\\.[0-9]+$", var.parameter_group.family))
    error_message = "parameter_group.family must be a Redshift family, such as redshift-2.0."
  }
}

variable "port" {
  description = <<-EOT
    The port clients connect to. Defaults to `5439`. From `5431` to `5455` or from `8191` to `8215`: AWS refuses other ports for every node type that uses managed storage, which are all the types it offers (RA3 and RG). Only the older DC2 types accepted `1150` to `65535`. Changing it updates the cluster in place and the security group's rules with it; the first plan afterwards shows only `metadata` changing, and applying it changes no resources.
  EOT
  type        = number
  default     = 5439
  nullable    = false

  validation {
    condition = floor(var.port) == var.port && (
      startswith(var.node_type, "dc2.")
      ? var.port >= 1150 && var.port <= 65535
      : (var.port >= 5431 && var.port <= 5455) || (var.port >= 8191 && var.port <= 8215)
    )
    error_message = "port must be from 5431 to 5455 or 8191 to 8215 (from 1150 to 65535 only for DC2 node types)."
  }
}

variable "publicly_accessible" {
  description = <<-EOT
    Give the cluster a public IP address. Defaults to `false`. In subnets with a route to an internet gateway, anyone on the internet whom `security_group_ingress` allows can then reach it. Prefer a private connection, such as a VPN or AWS Systems Manager port forwarding through an instance in the VPC, or the Amazon Redshift Data API, which needs no network access to the cluster.
  EOT
  type        = bool
  default     = false
  nullable    = false
}

variable "region" {
  description = <<-EOT
    The AWS Region to create the cluster and everything else in, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module.
  EOT
  type        = string
  default     = null
}

variable "security_group_egress" {
  description = <<-EOT
    More destinations the cluster may connect to, besides Amazon S3 (see `allow_s3_egress`). The cluster needs no outbound rules to answer clients. Add an entry for a feature that makes the cluster connect out through the VPC, such as a federated query to an Amazon RDS database, or, with `enhanced_vpc_routing`, `COPY` from Amazon DynamoDB or an Amazon EMR cluster. The keys are names you choose; they only identify each rule.

    Each entry takes:

    - `port` - (Required) The TCP port to allow.

    and exactly one of:

    - `cidr_ipv4` - An IPv4 range, such as `10.0.0.0/16`.
    - `cidr_ipv6` - An IPv6 range, such as `2001:db8::/56`.
    - `security_group_id` - A security group whose members the cluster may connect to.
    - `prefix_list_id` - A managed prefix list, such as the one for DynamoDB in the Region (`data.aws_ec2_managed_prefix_list` with name `com.amazonaws.<region>.dynamodb`).

    and optionally:

    - `description` - (Optional) What the destination is. Defaults to the key.
  EOT
  type = map(object({
    port              = number
    cidr_ipv4         = optional(string)
    cidr_ipv6         = optional(string)
    security_group_id = optional(string)
    prefix_list_id    = optional(string)
    description       = optional(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for s in values(var.security_group_egress) :
      length([for v in [s.cidr_ipv4, s.cidr_ipv6, s.security_group_id, s.prefix_list_id] : v if v != null]) == 1
    ])
    error_message = "Each security_group_egress entry needs exactly one of cidr_ipv4, cidr_ipv6, security_group_id or prefix_list_id."
  }

  validation {
    condition = alltrue([
      for s in values(var.security_group_egress) :
      (s.cidr_ipv4 == null || can(cidrnetmask(s.cidr_ipv4))) && (s.cidr_ipv6 == null || (can(cidrhost(s.cidr_ipv6, 0)) && strcontains(coalesce(s.cidr_ipv6, "-"), ":")))
    ])
    error_message = "security_group_egress: cidr_ipv4 must be an IPv4 range such as 10.0.0.0/16, and cidr_ipv6 an IPv6 range such as 2001:db8::/56."
  }

  validation {
    condition     = alltrue([for s in values(var.security_group_egress) : s.port >= 1 && s.port <= 65535 && floor(s.port) == s.port])
    error_message = "security_group_egress: port must be a whole number from 1 to 65535."
  }
}

variable "security_group_ids" {
  description = <<-EOT
    IDs of more security groups to attach to the cluster, besides the one the module creates, such as a group shared by every data warehouse.
  EOT
  type        = list(string)
  default     = []
  nullable    = false
}

variable "security_group_ingress" {
  description = <<-EOT
    Who can connect to the cluster. The module creates a security group for the cluster that allows the database port (`port`) over TCP from each source listed here, and from nothing else. With the default, `{}`, no client can connect. The keys are names you choose; they only identify each rule, so a security group created in the same configuration can be used.

    Each source takes exactly one of:

    - `cidr_ipv4` - An IPv4 range, such as `10.0.0.0/16`.
    - `cidr_ipv6` - An IPv6 range, such as `2001:db8::/56`.
    - `security_group_id` - A security group whose members may connect, such as the group of your application servers.
    - `prefix_list_id` - A managed prefix list of ranges.

    and optionally:

    - `description` - (Optional) What the source is. Defaults to the key.
  EOT
  type = map(object({
    cidr_ipv4         = optional(string)
    cidr_ipv6         = optional(string)
    security_group_id = optional(string)
    prefix_list_id    = optional(string)
    description       = optional(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for s in values(var.security_group_ingress) :
      length([for v in [s.cidr_ipv4, s.cidr_ipv6, s.security_group_id, s.prefix_list_id] : v if v != null]) == 1
    ])
    error_message = "Each security_group_ingress entry needs exactly one of cidr_ipv4, cidr_ipv6, security_group_id or prefix_list_id."
  }

  validation {
    condition = alltrue([
      for s in values(var.security_group_ingress) :
      (s.cidr_ipv4 == null || can(cidrnetmask(s.cidr_ipv4))) && (s.cidr_ipv6 == null || (can(cidrhost(s.cidr_ipv6, 0)) && strcontains(coalesce(s.cidr_ipv6, "-"), ":")))
    ])
    error_message = "security_group_ingress: cidr_ipv4 must be an IPv4 range such as 10.0.0.0/16, and cidr_ipv6 an IPv6 range such as 2001:db8::/56."
  }
}

variable "skip_final_snapshot" {
  description = <<-EOT
    Delete the cluster without taking a final snapshot. Defaults to `false`: deleting the cluster first takes a snapshot named `<name>-final-<8 hex digits>`, which is kept until you delete it.
  EOT
  type        = bool
  default     = false
  nullable    = false
}

variable "snapshot_identifier" {
  description = <<-EOT
    The identifier of a snapshot to create the cluster from, such as a final snapshot of an earlier cluster. The node type and number of nodes may differ from the snapshot's, within what the snapshot's size allows. The master user and databases come from the snapshot, and the password is set as described in `master_password`.

    Used only when the cluster is created: changing it later does nothing.
  EOT
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = <<-EOT
    IDs of the subnets for the cluster, in `vpc_id`. The module creates a cluster subnet group, named after the cluster, with them. Use private subnets. Amazon Redshift places the cluster in one of their Availability Zones; with `availability_zone_relocation`, on by default, or `multi_az`, they must cover at least two. Changing them updates the subnet group in place, but a subnet the cluster uses cannot be removed.
  EOT
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.subnet_ids) > 0 && alltrue([for s in var.subnet_ids : startswith(s, "subnet-")])
    error_message = "subnet_ids must list one or more subnet IDs, such as subnet-0123456789abcdef0."
  }
}

variable "timeouts" {
  description = <<-EOT
    How long Terraform waits for the cluster to be created, updated or deleted, such as `120m`. Each defaults to `120m`.
  EOT
  type = object({
    create = optional(string, "120m")
    update = optional(string, "120m")
    delete = optional(string, "120m")
  })
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for t in [var.timeouts.create, var.timeouts.update, var.timeouts.delete] : can(regex("^[0-9]+(s|m|h)$", t))])
    error_message = "timeouts values must be durations such as 90m or 2h."
  }
}

variable "vpc_id" {
  description = <<-EOT
    The ID of the VPC the cluster is in, such as `vpc-0123456789abcdef0`: the VPC of `subnet_ids`. The module creates the cluster's security group in it.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = startswith(var.vpc_id, "vpc-")
    error_message = "vpc_id must be a VPC ID, such as vpc-0123456789abcdef0."
  }
}

