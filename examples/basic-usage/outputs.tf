output "aurora_endpoint" {
  value = module.test_aurora.aurora_cluster_endpoint
}

output "database_name" {
  value = module.test_aurora.database_name
}

output "security_group_id" {
  value = module.test_aurora.security_group_id
}

output "lambda_function_name" {
  value = module.test_aurora.lambda_function_name
}

# Sensitive outputs will only show <sensitive> in console
output "master_password" {
  value = module.test_aurora.master_password
  sensitive = true
}

output "readonly_password" {
  value = module.test_aurora.readonly_password
  sensitive = true
}

output "readwrite_password" {
  value = module.test_aurora.readwrite_password
  sensitive = true
} 