# Busca a VPC default quando create_rds = true e rds_vpc_id não foi fornecido.
data "aws_vpc" "default" {
  count   = var.create_rds && var.rds_vpc_id == "" ? 1 : 0
  default = true
}

# Busca as subnets da VPC default quando rds_subnet_ids não foi fornecido.
data "aws_subnets" "default" {
  count = var.create_rds && length(var.rds_subnet_ids) == 0 ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }
}
