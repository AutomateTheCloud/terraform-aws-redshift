variable "alarm" {
  description = "Alarm"
  type        = any
  default     = null
}

variable "backup" {
  description = "Backup"
  type        = any
  default     = null
}

variable "cluster_subnet_group" {
  description = "Cluster Subnet Group"
  type        = any
  default     = null
}

variable "credentials" {
  description = "Credentials"
  type        = any
  default     = null
}

variable "db_name" {
  description = "Database Name"
  type        = string
  default     = ""
}

variable "encryption" {
  description = "Encryption"
  type        = any
  default     = null
}

variable "engine_version" {
  # Constraints: Only version 1.0 is currently available.
  # https://awscli.amazonaws.com/v2/documentation/api/latest/reference/redshift/create-cluster.html
  description = "Engine Version"
  default     = "1.0"
}

variable "logging" {
  description = "Logging"
  type        = any
  default     = null
}

variable "maintenance" {
  description = "Maintenance"
  type        = any
  default     = null
}

variable "name" {
  description = "Cluster Name"
  type        = string
  default     = ""
}

variable "node" {
  description = "Node"
  type        = any
  default     = null
}

variable "parameter_group" {
  description = "Parameter Group"
  type        = any
  default     = null
}

variable "permissions" {
  description = "Permissions"
  type        = any
  default     = null
}

variable "port" {
  description = "Port"
  type        = number
  default     = 5439
}

variable "security_group_rules" {
  description = "Security Group Rules"
  type        = any
  default     = null
}

variable "snapshot_identifier" {
  description = "Snapshot ARN to create this Redshift Cluster from"
  type        = string
  default     = ""
}

# variable "subnets" {
# description = "Subnet IDs for Redshift Subnet Group"
# type        = list
# default     = []
# }

variable "timeouts" {
  description = "List of timeout values per action (`create`, `update` and `delete`)"
  type = object({
    create = string
    update = string
    delete = string
  })
  default = {
    create = "180m"
    update = "120m"
    delete = "120m"
  }
}

variable "vpc_id" {
  description = "VPC: ID"
  type        = string
  default     = ""
  validation {
    condition     = var.vpc_id != ""
    error_message = "VPC ID not Specified."
  }
}
