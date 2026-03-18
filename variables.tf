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
  description = <<-EOT
    Nome do usuário PostgreSQL que o Vault utilizará para se conectar ao banco.

    Comportamento conforme o cenário:
      1. create_rds = false
         O usuário já deve existir no banco externo com as permissões adequadas.
         Este valor é usado diretamente pelo Vault na connection string.

      2. create_rds = true, action NÃO invocada
         O RDS é provisionado mas o usuário NÃO é criado pelo Terraform.
         O valor deve corresponder a um usuário que será criado manualmente
         antes do Vault tentar se conectar.

      3. create_rds = true, action invocada
         (terraform apply -invoke=action.local_command.create_vault_user)
         Este valor define o nome do usuário que será criado no banco com
         permissões mínimas (CONNECT + USAGE/CREATE no schema public).
  EOT
  type        = string
}

variable "db_password" {
  description = <<-EOT
    Senha do usuário PostgreSQL que o Vault utilizará para se conectar ao banco.

    Comportamento conforme o cenário:
      1. create_rds = false
         Senha do usuário já existente no banco externo.

      2. create_rds = true, action NÃO invocada
         Senha do usuário que será criado manualmente no banco.

      3. create_rds = true, action invocada
         (terraform apply -invoke=action.local_command.create_vault_user)
         Senha que será definida para o usuário criado pela action.
  EOT
  type      = string
  sensitive = true
}

variable "db_sslmode" {
  description = "PostgreSQL sslmode: 'require' para produção, 'disable' para testes locais sem TLS"
  type        = string
  default     = "require"
}

variable "db_admin_user" {
  description = "Usuário master do RDS / administrador do PostgreSQL (com CREATEROLE). Usado para criar o db_user via script após o RDS subir. Obrigatório quando create_rds = true."
  type        = string
  default     = ""
}

variable "db_admin_password" {
  description = "Senha do usuário administrador do PostgreSQL (db_admin_user). Obrigatório quando create_rds = true."
  type        = string
  sensitive   = true
  default     = ""
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

