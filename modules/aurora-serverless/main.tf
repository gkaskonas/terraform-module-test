# Random password generation for database users
resource "random_password" "db_master_pass" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "db_readonly_pass" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "db_readwrite_pass" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Security group for the RDS cluster
resource "aws_security_group" "aurora_sg" {
  name        = "${var.name_prefix}-aurora-sg"
  description = "Security group for Aurora Serverless cluster"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.engine_name == "aurora-postgresql" ? 5432 : 3306
    to_port     = var.engine_name == "aurora-postgresql" ? 5432 : 3306
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-aurora-sg"
    }
  )
}

# Subnet group for the RDS cluster
resource "aws_db_subnet_group" "aurora" {
  name       = "${var.name_prefix}-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

# Aurora Serverless Cluster
resource "aws_rds_cluster" "aurora_serverless" {
  cluster_identifier      = "${var.name_prefix}-cluster"
  engine                  = var.engine_name
  engine_mode             = "serverless"
  database_name           = var.database_name
  master_username         = var.master_username
  master_password         = random_password.db_master_pass.result
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.preferred_backup_window
  skip_final_snapshot     = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name_prefix}-final-snapshot"
  db_subnet_group_name    = aws_db_subnet_group.aurora.name
  vpc_security_group_ids  = [aws_security_group.aurora_sg.id]
  
  scaling_configuration {
    auto_pause               = var.auto_pause
    max_capacity             = var.max_capacity
    min_capacity             = var.min_capacity
    seconds_until_auto_pause = var.seconds_until_auto_pause
    timeout_action           = var.timeout_action
  }

  tags = var.tags
}

# Create read-only and read-write users via a lambda function
resource "null_resource" "lambda_package" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOT
      cd ${path.module}/lambda && \
      npm install --production && \
      zip -r db_users.zip node_modules index.js
    EOT
  }
}

resource "aws_lambda_function" "db_users_lambda" {
  filename      = "${path.module}/lambda/db_users.zip"
  function_name = "${var.name_prefix}-db-users-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 60

  environment {
    variables = {
      DB_CLUSTER_ENDPOINT = aws_rds_cluster.aurora_serverless.endpoint
      DB_NAME             = var.database_name
      DB_PORT             = var.engine_name == "aurora-postgresql" ? "4510" : "4510"
      DB_MASTER_USERNAME  = var.master_username
      DB_MASTER_PASSWORD  = random_password.db_master_pass.result
      DB_ENGINE           = var.engine_name
      DB_READONLY_USER    = var.readonly_username
      DB_READONLY_PASS    = random_password.db_readonly_pass.result
      DB_READWRITE_USER   = var.readwrite_username
      DB_READWRITE_PASS   = random_password.db_readwrite_pass.result
    }
  }

  # Add tags to force recreation
  tags = {
    "LastModified" = timestamp()
  }

  depends_on = [
    null_resource.lambda_package,
    aws_rds_cluster.aurora_serverless
  ]
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.name_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# IAM policy for Lambda
resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.name_prefix}-lambda-policy"
  description = "IAM policy for DB users Lambda function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "rds:*",
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}


# Trigger Lambda after cluster is created
resource "null_resource" "invoke_lambda" {
    triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = "awslocal lambda invoke --function-name ${aws_lambda_function.db_users_lambda.function_name} --region ${var.aws_region} /tmp/lambda_output.json"
  }

  depends_on = [aws_lambda_function.db_users_lambda]
}

