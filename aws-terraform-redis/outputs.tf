output "replication_group_id" {
  description = "ID of the ElastiCache replication group."
  value       = aws_elasticache_replication_group.this.id
}

output "primary_endpoint_address" {
  description = "Address of the primary endpoint."
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Address of the reader endpoint."
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "port" {
  description = "Port number for the Redis cluster."
  value       = aws_elasticache_replication_group.this.port
}

output "security_group_id" {
  description = "Security group ID created for the Redis cluster."
  value       = aws_security_group.this.id
}

output "auth_token" {
  description = "Auth token for the Redis cluster (sensitive)."
  value       = length(random_password.auth_token) > 0 ? random_password.auth_token[0].result : ""
  sensitive   = true
}
