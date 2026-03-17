output "endpoint" {
  description = "Hostname do RDS (sem porta)"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Porta do RDS"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Nome do banco de dados"
  value       = aws_db_instance.this.db_name
}

output "security_group_id" {
  description = "ID do security group do RDS"
  value       = aws_security_group.rds.id
}
