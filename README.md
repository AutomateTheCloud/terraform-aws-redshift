# AWS - Redshift - Terraform Module
Terraform module for creating Redshift Clusters (AutomateTheCloud model)

***

## Usage
```hcl
module "redshift" {
  source    = "../"
  providers = { aws.this = aws.example }

  details = {
    scope       = "Demo"
    purpose     = "Redshift"
    environment = "dev"
    additional_tags = {
      "Project"   = "Project Name"
      "ProjectID" = "123456789"
      "Contact"   = "David Singer - david.singer@example.com"
    }
  }

  name                = "demo-redshift-dev"
  db_name             = "uetl"
  snapshot_identifier = ""
  engine_version      = "1.0"

  node = {
    count                = 2
    type                 = "dc2.large"
    public               = false
    enhanced_vpc_routing = true
  }

  encryption = {
    enabled = true
    # kms_key_id = "alias/data"
  }

  port = 5439

  credentials = {
    master = {
      username = "test"
      # password = "test1234"
    }
  }

  backup = {
    retention_period = 1
    schedule         = "rate(12 hours)"
  }

  maintenance = {
    window                = "tue:06:00-tue:08:00"
    allow_version_upgrade = true
    skip_final_snapshot   = true
  }

  security_group_rules = [
    {
      source      = "10.0.0.0/8"
      description = "CIDR Test"
    }
  ]

  permissions = {
    athena = {
      enabled = true
    }
    s3 = {
      read = {
        all = true
        bucket_arns = [
          "arn:aws:s3:::test-gate1-qa-use1",
          "arn:aws:s3:::test-gate1-qa-usw2"
        ]
      }
      write = {
        bucket_arns = [
          "arn:aws:s3:::test-gate2-qa-use1",
          "arn:aws:s3:::test-gate2-qa-usw2"
        ]
      }
    }
  }

  alarm = {
    cpu_utilization = {
      critical = 95
      warning  = 85
    }
    free_storage_space = {
      critical = 95
      warning  = 85
    }
  }

  logging = {
    enabled       = true
    bucket_name   = "logs-use1-012345678901"
    s3_key_prefix = "redshift/test-db/"
  }

  vpc_id = "vpc-00000000000000001"

  parameter_group = {
    # existing = "default.redshift-1.0"
    family = "redshift-1.0"
    parameter = [
      {
        name  = "require_ssl"
        value = "true"
      },
      {
        name  = "query_group"
        value = "example"
      },
      {
        name  = "enable_user_activity_logging"
        value = "true"
      }
    ]
    wlm_configuration_json_file = "${path.root}/files/wlm_json_configuration.json"
  }

  cluster_subnet_group = {
    # existing = null
    # subnets = [
      # "subnet-00c936061654bb0ed",
      # "subnet-0d4ce376f87b52485",
      # "subnet-056f66037f150bc30"
    # ]
    subnet_network_tag = "private"
  }

  timeouts = {
    create = "120m"
    update = "120m"
    delete = "120m"
  }
}
```

***

## Inputs
| Name | Description | Type | Default |
|------|-------------|:----:|:-------:|
| `alarm` | Alarm | `any` | |
| `backup` | Backup | `any` | |
| `cluster_subnet_group` | Cluster Subnet Group | `any` | |
| `credentials` | Credentials | `any` | |
| `db_name` | Database Name | `string` | |
| `encryption` | Encryption | `any` | |
| `engine_version` | Engine Version | `string` | `1.0` |
| `logging` | Logging | `any` | |
| `maintenance` | Maintenance | `any` | |
| `name` | Cluster Name | `string` | |
| `node` | Node | `any` | |
| `parameter_group` | Parameter Group | `any` | |
| `permissions` | Permissions | `any` | |
| `port` | Port | `number` | `5439` |
| `security_group_rules` | Security Group Rules | `number` | `5439` |
| `snapshot_identifier` | Snapshot ARN to create this Redshift Cluster from | `string` | |
 `timeouts` | [Timeouts](#timeouts) | `object` | |
| `vpc_id` | VPC ID | `string` | |

## Inputs (Details)
| Name | Description | Type | Default |
|------|-------------|:----:|:-------:|
| `details.scope` | (Required) Scope Name - What does this object belong to? (Organization Name, Project, etc) | `string` | |
| `details.scope_abbr` | (Optional) Scope [Abbreviation](#Abbreviations) Override | `string` | |
| `details.purpose` | (Required) Purpose Name - What is the purpose or function of this object, or what does this object serve? | `string` | |
| `details.purpose_abbr` | (Optional) Purpose [Abbreviation](#Abbreviations) Override | `string` | |
| `details.environment` | (Required) Environment Name | `string` | |
| `details.environment_abbr` | (Optional) Environment [Abbreviation](#Abbreviations) Override | `string` | |
| `details.additional_tags` | (Optional) [Additional Tags](#Additional-Tags) for resources | `map` | `[]` |

***

## Outputs
All outputs from this module are mapped to a single output named `metadata` to make it easier to capture all of the relevant metadata that would be useful when referenced by other stacks (requires only a single output reference in your code, instead of dozens!)

| Name | Description |
|:-----|:------------|
| `details.scope.name` | Scope name |
| `details.scope.abbr` | Scope abbreviation |
| `details.scope.machine` | Scope machine-friendly abbreviation |
| `details.purpose.name` | Purpose name |
| `details.purpose.abbr` | Purpose abbreviation |
| `details.purpose.machine` | Purpose machine-friendly abbreviation |
| `details.environment.name` | Environment name |
| `details.environment.abbr` | Environment abbreviation |
| `details.environment.machine` | Environment machine-friendly abbreviation |
| `details.tags` | Map of tags applied to all resources |
| `aws.account.id` | AWS Account ID |
| `aws.region.name` | AWS Region name, example: `us-east-1` |
| `aws.region.abbr` | AWS Region four letter abbreviation, example: `use1` |
| `aws.region.description` | AWS Region description, example: `US East (N. Virginia)` |
| `iam.role` | IAM - Role |
| `redshift.cluster` | Redshift - Cluster |
| `redshift.parameter_group` | Redshift - Parameter Group |
| `redshift.snapshot_schedule` | Redshift - Snapshot Schedule |
| `redshift.subnet_group` | Redshift - Subnet Group |
| `security_group` | Security Group |
| `sns.topic.critical` | SNS Topic - Critical |
| `sns.topic.warning` | SNS Topic - Warning |

***

## Notes

### Abbreviations
* When generating resource names, the module converts each identifier to a more 'machine-friendly' abbreviated format, removing all special characters, replacing spaces with underscores (_), and converting to lowercase. Example: 'Demo - Module' => 'demo_module'
* Not all resource names allow underscores. When those are encountered, the detail identifier will have the underscore removed (test_example => testexample) automatically. This machine-friendly abbreviation is referred to as 'machine' within the module.
* The abbreviations can be overridden by suppling the abbreviated names (ie: scope_abbr). This is useful when you have a long name and need the created resource names to be shorter. Some resources in AWS have shorter name constraints than others, or you may just prefer it shorter. NOTE: If specifying the Abbreviation, be sure to follow the convention of no spaces and no special characters (except for underscore), otherwise resoure creation may fail.

### Additional Tags
* You can specify additional tags for resources by adding to the `details.additional_tags` map.
```
additional_tags = {
  "Example"         = "Extra Tag"
  "Project"         = "Project Name"
  "CostCenter"      = "123456"
}
```

***

## Terraform Versions
Terraform ~> 1.11.0 is supported.

## Provider Versions
| Name | Version |
|------|---------|
| aws | `~> 5.93` |
