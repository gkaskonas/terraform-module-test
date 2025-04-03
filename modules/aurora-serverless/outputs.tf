output "aurora_cluster_endpoint" {
  description = "RDS Aurora Serverless cluster endpoint"
  value       = aws_rds_cluster.aurora_serverless.endpoint
}

output "aurora_cluster_id" {
  description = "RDS Aurora Serverless cluster identifier"
  value       = aws_rds_cluster.aurora_serverless.cluster_identifier
}

output "database_name" {
  description = "Name of the initial database"
  value       = aws_rds_cluster.aurora_serverless.database_name
}

output "security_group_id" {
  description = "Security group ID attached to the Aurora cluster"
  value       = aws_security_group.aurora_sg.id
}

output "lambda_function_name" {
  description = "Name of the user management Lambda function"
  value       = aws_lambda_function.db_users_lambda.function_name
}

output "master_password" {
  description = "Master database password (sensitive)"
  value       = random_password.db_master_pass.result
  sensitive   = true
}

output "readonly_password" {
  description = "Read-only user password (sensitive)"
  value       = random_password.db_readonly_pass.result
  sensitive   = true
}

output "readwrite_password" {
  description = "Read-write user password (sensitive)"
  value       = random_password.db_readwrite_pass.result
  sensitive   = true
}

output "db_subnet_group_name" {
  description = "Name of the created DB subnet group"
  value       = aws_db_subnet_group.aurora.name
}

output "lambda_iam_role_arn" {
  description = "ARN of the IAM role used by Lambda"
  value       = aws_iam_role.lambda_role.arn
} 