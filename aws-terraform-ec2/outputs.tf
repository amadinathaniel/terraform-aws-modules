output "launch_template_id" {
  description = "ID of the launch template."
  value       = aws_launch_template.this.id
}

output "launch_template_latest_version" {
  description = "Latest version of the launch template."
  value       = aws_launch_template.this.latest_version
}

output "autoscaling_group_id" {
  description = "ID of the Auto Scaling Group (if created)."
  value       = length(aws_autoscaling_group.this) > 0 ? aws_autoscaling_group.this[0].id : ""
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group (if created)."
  value       = length(aws_autoscaling_group.this) > 0 ? aws_autoscaling_group.this[0].name : ""
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group (if created)."
  value       = length(aws_autoscaling_group.this) > 0 ? aws_autoscaling_group.this[0].arn : ""
}

output "instance_id" {
  description = "ID of the standalone EC2 instance (if created)."
  value       = length(aws_instance.this) > 0 ? aws_instance.this[0].id : ""
}

output "private_ip" {
  description = "Private IP of the standalone instance (if created)."
  value       = length(aws_instance.this) > 0 ? aws_instance.this[0].private_ip : ""
}

output "public_ip" {
  description = "Public IP of the standalone instance (if created)."
  value       = length(aws_instance.this) > 0 ? aws_instance.this[0].public_ip : ""
}

output "security_group_id" {
  description = "Security group ID created for the instances."
  value       = aws_security_group.this.id
}

output "iam_role_arn" {
  description = "ARN of the IAM role (if created)."
  value       = length(aws_iam_role.this) > 0 ? aws_iam_role.this[0].arn : ""
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile (if created)."
  value       = length(aws_iam_instance_profile.this) > 0 ? aws_iam_instance_profile.this[0].name : ""
}

output "eip_public_ip" {
  description = "Elastic IP address (if allocated)."
  value       = length(aws_eip.this) > 0 ? aws_eip.this[0].public_ip : ""
}
