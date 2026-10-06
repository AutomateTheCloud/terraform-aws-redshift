# Basic cluster

A single-node Amazon Redshift cluster with one `ra3.large` node and an `analytics` database, in private subnets you give. Anything in the VPC can connect on port 5439, over TLS. Amazon Redshift generates the master password for `awsuser` and keeps it in AWS Secrets Manager.

Everything else uses the module's defaults: encryption with a key AWS owns, automated snapshots kept for 7 days, a final snapshot when the cluster is deleted, an IAM role with no permissions, outbound HTTPS to Amazon S3 only, and alarms to two SNS topics with no subscribers.

## Run it

Choose a VPC and private subnets in at least two Availability Zones:

```shell
terraform init
terraform apply -var 'vpc_id=vpc-0123456789abcdef0' -var 'subnet_ids=["subnet-0123456789abcdef0","subnet-0fedcba9876543210"]'
```

Creating the cluster takes about 5 to 10 minutes. Read the master password from the secret in the `cluster` output:

```shell
aws secretsmanager get-secret-value --secret-id <secret_arn> --query SecretString --output text
```

and connect from an instance in the VPC with `psql "host=<dns_name> port=5439 dbname=analytics user=awsuser sslmode=require"`. Or run SQL without network access through the Data API:

```shell
aws redshift-data execute-statement --cluster-identifier example-basic --database analytics --secret-arn <secret_arn> --sql "select current_user"
```

`terraform destroy`, with the same `-var` options, deletes the cluster and keeps a final snapshot, `example-basic-final-<8 hex digits>`, until you delete it.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

- <a name="requirement_random"></a> [random](#requirement_random) (~> 3.0)

### Required Inputs

The following input variables are required:

#### <a name="input_subnet_ids"></a> [subnet_ids](#input_subnet_ids)

Description: IDs of private subnets for the cluster, in at least two Availability Zones

Type: `list(string)`

#### <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id)

Description: ID of the VPC to create the cluster in

Type: `string`

### Outputs

The following outputs are exported:

#### <a name="output_cluster"></a> [cluster](#output_cluster)

Description: Where to connect, and the Secrets Manager secret that holds the master password
<!-- END_TF_DOCS -->
