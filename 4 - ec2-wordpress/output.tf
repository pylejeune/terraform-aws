output "public_ip" {
  description = "Adresse public"
  value       = aws_instance.wordpress.public_ip
}

output "db_username" {
  description = "DB user"
  value       = aws_ssm_parameter.db_username.value
  sensitive   = true
}

output "db_password" {
  description = "DB password"
  value       = aws_ssm_parameter.db_password.value
  sensitive   = true
}