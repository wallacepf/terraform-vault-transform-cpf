# ── Actions ───────────────────────────────────────────────────────────────────
#
# Actions são invocadas manualmente quando necessário:
#
#   terraform apply -invoke=action.local_command.create_vault_user
#
# Requer:
#   - Terraform >= 1.14.0
#   - psql instalado no host que executa o Terraform
#   - Acesso de rede ao endpoint do PostgreSQL

# Cria o usuário do Vault no PostgreSQL com permissões mínimas (least privilege):
#   - CONNECT no banco
#   - USAGE + CREATE no schema public
#     (Vault usa o mesmo usuário para criar as tabelas na inicialização e para
#      operar em runtime — como dono das tabelas, tem DML implicitamente)
#
# Idempotente: não recria o usuário se já existir.
#
# Segurança:
#   - Senha do admin em PGPASSWORD — não aparece em argumentos de processo
#   - Credenciais do vault user passadas via psql -v e referenciadas com :'var'
#     para quoting correto como SQL string literals
#   - format('%I'/'%L') protege identifiers e literals contra caracteres especiais
#   - replace() escapa single quotes no contexto de shell single-quoted
action "local_command" "create_vault_user" {
  config {
    command = "bash"
    stdin   = <<-EOT
      set -euo pipefail
      PGPASSWORD='${replace(var.db_admin_password, "'", "'\\''")}' psql \
        -h '${local.pg_host}' \
        -p '${local.pg_port}' \
        -U '${var.db_admin_user}' \
        -d '${local.pg_db}' \
        --no-password \
        -v vault_user='${replace(var.db_user, "'", "'\\''")}' \
        -v vault_pass='${replace(var.db_password, "'", "'\\''")}' \
        <<'SQL'
      DO $body$
      DECLARE
        v_user text := :'vault_user';
        v_pass text := :'vault_pass';
      BEGIN
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = v_user) THEN
          EXECUTE format('CREATE USER %I WITH PASSWORD %L', v_user, v_pass);
        END IF;
        EXECUTE format('GRANT CONNECT ON DATABASE %I TO %I', current_database(), v_user);
        EXECUTE format('GRANT USAGE, CREATE ON SCHEMA public TO %I', v_user);
      END
      $body$;
      SQL
    EOT
  }
}
