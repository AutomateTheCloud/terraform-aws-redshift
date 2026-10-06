# Changelog

All notable changes to this module are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the module uses [semantic versioning](https://semver.org/): a new major version means callers must change their code.

## [Unreleased]

## [1.0.1] - 2026-10-06

### Changed

- The copyright year in `NOTICE` and the file headers is now 2026, the year the module was rebuilt and released as 1.0.0.
- `CLAUDE.md`, the working rules shared by every Automate the Cloud module, adds the lessons learned while rebuilding the modules.

## [1.0.0] - 2026-10-05

Initial release.

### Added

- A provisioned Amazon Redshift cluster with secure defaults: always encrypted, the master password kept in AWS Secrets Manager instead of Terraform state, TLS required, no network access until you allow a source, no public address, enhanced VPC routing, and a final snapshot on delete.
- Single-node, multi-node and Multi-AZ clusters, with the cluster subnet group and a parameter group of your parameters.
- A security group that allows the cluster's port from IPv4 and IPv6 ranges, security groups and prefix lists, with outbound HTTPS to Amazon S3 and other outbound rules where you add them.
- An IAM role, the cluster's default for `COPY` and `UNLOAD`, with the policies you give it, and more roles of your own.
- Your own KMS key for the data and the Secrets Manager secret, or your own master password.
- Automated snapshot retention and schedules, manual snapshot retention, maintenance windows and tracks, and restoring from a snapshot.
- Audit logging to CloudWatch Logs, in log groups with their own retention and optional KMS key, or to Amazon S3.
- CloudWatch alarms on health, CPU use and disk space, notifying two Amazon SNS topics, optionally encrypted.
- `region`, to create the cluster in a Region other than the provider's.
- A `metadata` output with everything the module created.
- Offline tests, and examples for a basic cluster and most options together.

[Unreleased]: https://github.com/AutomateTheCloud/terraform-aws-redshift/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/AutomateTheCloud/terraform-aws-redshift/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/AutomateTheCloud/terraform-aws-redshift/releases/tag/v1.0.0
