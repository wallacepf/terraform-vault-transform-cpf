locals {
  resolved_vpc_id     = var.rds_vpc_id != "" ? var.rds_vpc_id : try(data.aws_vpc.default[0].id, "")
  resolved_subnet_ids = length(var.rds_subnet_ids) > 0 ? var.rds_subnet_ids : try(data.aws_subnets.default[0].ids, [])

  pg_host = var.create_rds ? module.rds[0].endpoint : var.db_host
  pg_port = var.create_rds ? module.rds[0].port     : var.db_port
  pg_db   = var.create_rds ? module.rds[0].db_name  : var.db_name
}

module "rds" {
  count  = var.create_rds ? 1 : 0
  source = "./modules/rds"

  identifier          = var.rds_identifier
  db_name             = var.db_name
  db_username         = var.db_admin_user
  db_password         = var.db_admin_password
  vpc_id              = local.resolved_vpc_id
  subnet_ids          = local.resolved_subnet_ids
  instance_class      = var.rds_instance_class
  allowed_cidr_blocks = var.rds_allowed_cidr_blocks
  publicly_accessible = var.rds_publicly_accessible

}




module "vault_tokenization" {
  source = "./modules/vault_tokenization"

  vault_mount_path = vault_mount.transform.path
  role_name        = vault_transform_role.role.name

  db_host     = local.pg_host
  db_port     = local.pg_port
  db_name     = local.pg_db
  db_user     = var.db_user
  db_password = var.db_password
  db_sslmode  = var.db_sslmode

  depends_on = [module.rds]
}