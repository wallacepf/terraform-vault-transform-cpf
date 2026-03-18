output "rds_endpoint" {
  description = "Endpoint do RDS criado (disponível quando create_rds = true)"
  value       = var.create_rds ? module.rds[0].endpoint : null
}
