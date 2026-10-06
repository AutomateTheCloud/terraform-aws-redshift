# Complete

Most of the module's options together:

- Two `ra3.large` nodes, with an `analytics` database and the master user `warehouse_admin`.
- A KMS key of your own, which encrypts the data and snapshots, the Secrets Manager secret that holds the master password, and the alarm topics. Its key policy lets CloudWatch publish to the topics.
- Access from one security group only, created by the example for your application servers.
- Read access to one S3 bucket of yours, through the cluster's default IAM role, for `COPY ... IAM_ROLE default`.
- Automatic workload management with short query acceleration, through the parameter group, which also requires TLS.
- Automated snapshots every 12 hours, kept for 14 days.
- Audit logs in CloudWatch Logs, kept for 30 days.
- A CPU alarm at 85 and 95 percent instead of 80 and 90.

## Run it

Choose a VPC, private subnets in at least two Availability Zones, and a bucket in the same Region with data to load:

```shell
terraform init
terraform apply -var 'vpc_id=vpc-0123456789abcdef0' -var 'subnet_ids=["subnet-0123456789abcdef0","subnet-0fedcba9876543210"]' -var 'data_bucket_name=my-data-bucket'
```

With enhanced VPC routing, on by default, the cluster reaches S3 through the VPC: the subnets' route tables need an S3 gateway endpoint or a route to a NAT gateway. Then, as the master user:

```sql
CREATE TABLE sales (id INT, amount DECIMAL(10,2));
COPY sales FROM 's3://my-data-bucket/sales/' IAM_ROLE default FORMAT AS CSV;
```

Subscribe to the topics in the `cluster` output's `alarm_topics` to receive the alarms, for example with `aws sns subscribe --topic-arn <arn> --protocol email --notification-endpoint you@example.com`.

`terraform destroy`, with the same `-var` options, deletes the cluster and keeps a final snapshot, `example-complete-final-<8 hex digits>`, until you delete it. The KMS key is scheduled for deletion after 7 days; the snapshot cannot be restored once the key is deleted.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

- <a name="requirement_random"></a> [random](#requirement_random) (~> 3.0)

### Required Inputs

The following input variables are required:

#### <a name="input_data_bucket_name"></a> [data_bucket_name](#input_data_bucket_name)

Description: Name of an existing S3 bucket, in the same Region, that the cluster may read with COPY

Type: `string`

#### <a name="input_subnet_ids"></a> [subnet_ids](#input_subnet_ids)

Description: IDs of private subnets for the cluster, in at least two Availability Zones

Type: `list(string)`

#### <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id)

Description: ID of the VPC to create the cluster in

Type: `string`

### Outputs

The following outputs are exported:

#### <a name="output_cluster"></a> [cluster](#output_cluster)

Description: Where to connect, the Secrets Manager secret that holds the master password, and the alarm topics to subscribe to
<!-- END_TF_DOCS -->
