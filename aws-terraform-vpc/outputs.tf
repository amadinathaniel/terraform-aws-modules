output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Map of availability zone to public subnet ID."
  value       = { for az, subnet in aws_subnet.public : az => subnet.id }
}

output "private_subnet_ids" {
  description = "Map of availability zone to private subnet ID."
  value       = { for az, subnet in aws_subnet.private : az => subnet.id }
}

output "database_subnet_ids" {
  description = "Map of availability zone to database subnet ID."
  value       = { for az, subnet in aws_subnet.database : az => subnet.id }
}

output "cache_subnet_ids" {
  description = "Map of availability zone to cache subnet ID."
  value       = { for az, subnet in aws_subnet.cache : az => subnet.id }
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group."
  value       = length(aws_db_subnet_group.this) > 0 ? aws_db_subnet_group.this[0].name : ""
}

output "elasticache_subnet_group_name" {
  description = "Name of the ElastiCache subnet group."
  value       = length(aws_elasticache_subnet_group.this) > 0 ? aws_elasticache_subnet_group.this[0].name : ""
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs."
  value       = aws_nat_gateway.this[*].id
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway."
  value       = aws_internet_gateway.this.id
}
