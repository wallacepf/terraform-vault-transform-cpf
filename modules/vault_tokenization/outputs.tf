output "transformation_names" {
  description = "Nomes de todas as transformações de tokenização criadas"
  value       = keys(local.tokenization_transformations)
}
