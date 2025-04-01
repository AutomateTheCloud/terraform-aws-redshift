terraform {
  required_version = "~> 1.11.0"
}

##-----------------------------------------------------------------------------
# Providers
provider "aws" {
  alias  = "example"
  region = "us-east-1"
}

##-----------------------------------------------------------------------------
# Module: Redshift
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

##-----------------------------------------------------------------------------
# Outputs
output "metadata" {
  description = "Metadata"
  value       = module.redshift.metadata
}
