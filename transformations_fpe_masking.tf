# FPE Parcial Nao Deterministico
resource "vault_transform_transformation" "cpf" {
  path             = vault_mount.transform.path
  name             = "cpf"
  type             = "fpe"
  template         = vault_transform_template.cpf-template.name
  tweak_source     = "generated"
  allowed_roles    = ["${vault_transform_role.role.name}"]
  deletion_allowed = true
}

# FPE Parcial Deterministico
resource "vault_transform_transformation" "cnpj" {
  path             = vault_mount.transform.path
  name             = "cnpj"
  type             = "fpe"
  template         = vault_transform_template.cnpj-template.name
  tweak_source     = "internal"
  allowed_roles    = ["${vault_transform_role.role.name}"]
  deletion_allowed = true
}


# FPE Total Nao Deterministico Nao Reversivel
resource "vault_transform_transformation" "email" {
  path             = vault_mount.transform.path
  name             = "email"
  type             = "fpe"
  template         = vault_transform_template.email-template.name
  tweak_source     = "generated"
  allowed_roles    = ["${vault_transform_role.role.name}"]
  deletion_allowed = true
}

# FPE Total Deterministico Nao Reversivel
#FPE Encode
resource "vault_transform_transformation" "telefone" {
  path             = vault_mount.transform.path
  name             = "telefone"
  type             = "fpe"
  template         = vault_transform_template.telefone-template.name
  tweak_source     = "generated"
  allowed_roles    = ["${vault_transform_role.role.name}"]
  deletion_allowed = true
}



# FPE Total Deterministico
resource "vault_transform_transformation" "conta" {
  path             = vault_mount.transform.path
  name             = "conta"
  type             = "fpe"
  template         = vault_transform_template.bank_acct_mask_first6.name
  tweak_source     = "internal"
  allowed_roles    = ["${vault_transform_role.role.name}"]
  deletion_allowed = true
}

# FPE Total Deterministico
resource "vault_transform_transformation" "agencia" {
  path             = vault_mount.transform.path
  name             = "agencia"
  type             = "masking"
  template         = vault_transform_template.bank_agency.name
  tweak_source     = "internal"
  allowed_roles    = ["${vault_transform_role.role.name}"]
  deletion_allowed = true
}

# FPE Total Deterministico
resource "vault_transform_transformation" "data" {
  path             = vault_mount.transform.path
  name             = "data"
  type             = "fpe"
  template         = vault_transform_template.br_date_mask_full.name
  tweak_source     = "internal"
  allowed_roles    = ["${vault_transform_role.role.name}"]
  deletion_allowed = true
}

# FPE Total Deterministico
resource "vault_transform_transformation" "rg" {
  path             = vault_mount.transform.path
  name             = "rg"
  type             = "fpe"
  template         = vault_transform_template.rg-template.name
  tweak_source     = "internal"
  allowed_roles    = ["${vault_transform_role.role.name}"]
  deletion_allowed = true
}

# FPE Total Nao Deterministico
resource "vault_transform_transformation" "cnh" {
  path             = vault_mount.transform.path
  name             = "cnh"
  type             = "fpe"
  template         = vault_transform_template.cnh-template.name
  tweak_source     = "generated"
  allowed_roles    = ["${vault_transform_role.role.name}"]
  deletion_allowed = true
}

# FPE Total Nao Deterministico
resource "vault_transform_transformation" "cartao" {
  path             = vault_mount.transform.path
  name             = "cartao"
  type             = "fpe"
  template         = "builtin/creditcardnumber"
  tweak_source     = "generated"
  allowed_roles    = ["${vault_transform_role.role.name}"]
  deletion_allowed = true
}