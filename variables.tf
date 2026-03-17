# ── Banco de dados para tokenização ──────────────────────────────────────────

variable "create_rds" {
  description = "Quando true, provisiona um AWS RDS PostgreSQL e configura o Vault automaticamente. Quando false, db_host deve ser fornecido."
  type        = bool
  default     = false
}

variable "db_host" {
  description = "Host do PostgreSQL (obrigatório quando create_rds = false)"
  type        = string
  default     = ""
}

variable "db_port" {
  description = "Porta do PostgreSQL"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
  default     = "tokens"
}

variable "db_user" {
  description = "Usuário de runtime do PostgreSQL (SELECT/INSERT/UPDATE)"
  type        = string
}

variable "db_password" {
  description = "Senha do usuário de runtime"
  type        = string
  sensitive   = true
}

variable "ddl_user" {
  description = "Usuário DDL do PostgreSQL para inicialização do schema (CREATE TABLE)"
  type        = string
}

variable "ddl_password" {
  description = "Senha do usuário DDL"
  type        = string
  sensitive   = true
}

variable "db_sslmode" {
  description = "PostgreSQL sslmode: 'require' para produção, 'disable' para testes locais sem TLS"
  type        = string
  default     = "require"
}

# ── Variáveis exclusivas do RDS (usadas apenas quando create_rds = true) ─────

variable "rds_identifier" {
  description = "Identificador da instância RDS"
  type        = string
  default     = "vault-tokenization-db"
}

variable "rds_vpc_id" {
  description = "ID da VPC para o RDS (obrigatório quando create_rds = true)"
  type        = string
  default     = ""
}

variable "rds_subnet_ids" {
  description = "IDs das subnets para o DB subnet group (obrigatório quando create_rds = true)"
  type        = list(string)
  default     = []
}

variable "rds_instance_class" {
  description = "Classe da instância RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allowed_cidr_blocks" {
  description = "Blocos CIDR com acesso à porta 5432 do RDS"
  type        = list(string)
  default     = []
}

variable "aws_region" {
  description = "Região AWS (necessária apenas quando create_rds = true)"
  type        = string
  default     = "us-east-1"
}

