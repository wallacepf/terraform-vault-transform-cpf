variable "vault_mount_path" {
  description = "Path of the Vault Transform mount"
  type        = string
}

variable "role_name" {
  description = "Vault Transform role name allowed to use these transformations"
  type        = string
}

variable "db_host" {
  description = "PostgreSQL host"
  type        = string
}

variable "db_port" {
  description = "PostgreSQL port"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "tokens"
}

variable "db_user" {
  description = "PostgreSQL runtime user (SELECT/INSERT/UPDATE)"
  type        = string
}

variable "db_password" {
  description = "PostgreSQL runtime user password"
  type        = string
  sensitive   = true
}

variable "ddl_user" {
  description = "PostgreSQL DDL user for schema initialization (CREATE TABLE)"
  type        = string
}

variable "ddl_password" {
  description = "PostgreSQL DDL user password"
  type        = string
  sensitive   = true
}

variable "db_sslmode" {
  description = "PostgreSQL sslmode: 'require' para produção, 'disable' para testes locais sem TLS"
  type        = string
  default     = "require"
}
