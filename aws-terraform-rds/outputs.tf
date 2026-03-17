output "db_instance_id" {
  description = "ID of the RDS instance."
  value       = aws_db_instance.this.id
}

output "db_instance_endpoint" {
  description = "Connection endpoint for the RDS instance."
  value       = aws_db_instance.this.endpoint
}

output "db_instance_address" {
  description = "Hostname of the RDS instance."
  value       = aws_db_instance.this.address
}

output "db_instance_port" {
  description = "Port of the RDS instance."
  value       = aws_db_instance.this.port
}

output "db_instance_arn" {
  description = "ARN of the RDS instance."
  value       = aws_db_instance.this.arn
}

output "db_name" {
  description = "Name of the default database."
  value       = aws_db_instance.this.db_name
}

output "security_group_id" {
  description = "Security group ID created for the RDS instance."
  value       = aws_security_group.this.id
}

output "master_password_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the master password."
  value       = aws_secretsmanager_secret.master_password.arn
}

output "master_password_secret_name" {
  description = "Name of the Secrets Manager secret containing the master password."
  value       = aws_secretsmanager_secret.master_password.name
}

output "master_username" {
  description = "Master username for the database."
  value       = var.username
}

output "master_password" {
  description = "Master password for the database."
  value       = random_password.master.result
  sensitive   = true
}
