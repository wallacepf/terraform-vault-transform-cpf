variable "identifier" {
  description = "Identificador da instância RDS"
  type        = string
  default     = "vault-tokenization-db"
}

variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
  default     = "tokens"
}

variable "db_username" {
  description = "Usuário master do PostgreSQL"
  type        = string
}

variable "db_password" {
  description = "Senha do usuário master"
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "ID da VPC onde o RDS será provisionado"
  type        = string
}

variable "subnet_ids" {
  description = "IDs das subnets para o DB subnet group (mínimo 2, em AZs diferentes)"
  type        = list(string)
}

variable "instance_class" {
  description = "Classe da instância RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "allowed_cidr_blocks" {
  description = "Blocos CIDR com acesso à porta 5432"
  type        = list(string)
  default     = []
}

variable "publicly_accessible" {
  description = "Quando true, o RDS recebe um endpoint público. Usar apenas para testes — em produção mantenha false e acesse via VPC."
  type        = bool
  default     = false
}

