locals {
  pg_conn = "postgresql://{{username}}:{{password}}@${var.db_host}:${var.db_port}/${var.db_name}?sslmode=${var.db_sslmode}"

  # convergent = true  → token determinístico (mesmo valor sempre gera mesmo token, reversível)
  # convergent = false → token não-determinístico (mesmo valor gera tokens diferentes, reversível)
  tokenization_transformations = {
    nome_pessoa = { convergent = true }
    endereco    = { convergent = false }
    valores     = { convergent = false }
    contrato    = { convergent = false }
    produto     = { convergent = false }
    ticket      = { convergent = false }
    pix         = { convergent = true }
    empresa     = { convergent = true }
    outros      = { convergent = true }
  }
}

# 1) Store SQL por tipo de tokenização
resource "vault_generic_endpoint" "store" {
  for_each = local.tokenization_transformations

  path                 = "${var.vault_mount_path}/stores/${each.key}_store"
  ignore_absent_fields = true
  disable_read         = true

  data_json = jsonencode({
    type                      = "sql"
    driver                    = "postgres"
    connection_string         = local.pg_conn
    username                  = var.db_user
    password                  = var.db_password
    supported_transformations = ["tokenization"]
  })
}

# 2) Inicialização do schema (DDL) — cria as tabelas no PostgreSQL para cada store
resource "vault_generic_endpoint" "store_schema" {
  for_each = local.tokenization_transformations

  path                 = "${var.vault_mount_path}/stores/${each.key}_store/schema"
  ignore_absent_fields = true
  disable_read         = true

  data_json = jsonencode({
    username            = var.db_user
    password            = var.db_password
    transformation_type = "tokenization"
  })

  depends_on = [vault_generic_endpoint.store]
}

# 3) Transformação de tokenização vinculada ao seu próprio store
resource "vault_generic_endpoint" "tokenization" {
  for_each = local.tokenization_transformations

  path                 = "${var.vault_mount_path}/transformations/tokenization/${each.key}"
  ignore_absent_fields = true
  disable_read         = true

  data_json = jsonencode({
    mapping_mode     = "default"
    convergent       = each.value.convergent
    allowed_roles    = [var.role_name]
    stores           = ["${each.key}_store"]
    deletion_allowed = true
  })

  depends_on = [vault_generic_endpoint.store_schema]
}
