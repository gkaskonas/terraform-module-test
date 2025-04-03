# Aurora Serverless Terraform Module

Deploy a secure, serverless Aurora cluster with automated user management.

## Features

- 🛡️ Encryption at rest (AWS KMS)
- 🔑 Automatic password generation
- 👥 Read-only/read-write user creation
- 🚀 Serverless scaling configuration
- 🔄 Idempotent user management via Lambda

## Usage

```hcl
module "aurora" {
  source = "github.com/your-org/terraform-aws-aurora-serverless?ref=v1.0.0"

  # Required parameters
  name_prefix        = "prod-app"
  aws_region         = "us-west-2"
  engine_name        = "aurora-postgresql" # or "aurora-mysql"
  database_name      = "appdb"
  vpc_id             = "vpc-123456"
  subnet_ids         = ["subnet-123", "subnet-456"]
  allowed_cidr_blocks = ["10.0.0.0/16"]

  # Optional parameters
  master_username    = "admin"
  auto_pause         = true
  max_capacity       = 16
  min_capacity       = 2
  storage_encrypted  = true
  kms_key_id         = "arn:aws:kms:..." # optional custom KMS key
}

output "db_endpoint" {
  value = module.aurora.aurora_cluster_endpoint
}
```

## Inputs

| Name                    | Description                           | Type         | Default             |
| ----------------------- | ------------------------------------- | ------------ | ------------------- |
| `name_prefix`         | Resource name prefix                  | string       | Required            |
| `engine_name`         | "aurora-postgresql" or "aurora-mysql" | string       | Required            |
| `database_name`       | Initial database name                 | string       | Required            |
| `vpc_id`              | VPC ID for cluster placement          | string       | Required            |
| `subnet_ids`          | Subnet IDs for DB subnet group        | list(string) | Required            |
| `allowed_cidr_blocks` | Allowed CIDR blocks for DB access     | list(string) | `["10.0.0.0/16"]` |
| `storage_encrypted`   | Enable storage encryption             | bool         | `true`            |
| `kms_key_id`          | Custom KMS key ARN                    | string       | `null`            |
| `auto_pause`          | Enable auto-pause                     | bool         | `true`            |
| `max_capacity`        | Max ACU capacity                      | number       | `16`              |
| `min_capacity`        | Min ACU capacity                      | number       | `1`               |

## Outputs

- `aurora_cluster_endpoint`: Cluster endpoint
- `database_name`: Initial database name
- `security_group_id`: Security group ID
- `lambda_function_name`: User management Lambda name
- `master_password`: Master password (sensitive)
- `readonly_password`: Read-only user password (sensitive)
- `readwrite_password`: Read-write user password (sensitive)

## Security

- 🔒 Passwords are generated with Terraform's `random_password`
- 🔑 Encryption uses AWS KMS (default or custom key)
- 🔐 IAM role with least privilege for Lambda
- 🛡️ Security group restricts DB access to specified CIDRs

## Requirements

- Terraform >= 1.0
- AWS Provider >= 4.0
- Node.js 18.x (for Lambda)

## Development

```bash
# Test with LocalStack
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
cd examples/basic-usage
tflocal init
tflocal apply
```
