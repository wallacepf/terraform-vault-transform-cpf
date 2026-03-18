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
        -c "DO \$body\$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${replace(var.db_user, "'", "''")}') THEN EXECUTE format('CREATE USER %I WITH PASSWORD %L', '${replace(var.db_user, "'", "''")}', '${replace(var.db_password, "'", "''")}'); END IF; EXECUTE format('GRANT CONNECT ON DATABASE %I TO %I', current_database(), '${replace(var.db_user, "'", "''")}'); EXECUTE format('GRANT USAGE, CREATE ON SCHEMA public TO %I', '${replace(var.db_user, "'", "''")}'); END \$body\$;"
    EOT
  }
}
