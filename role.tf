

resource "vault_transform_role" "role" {
  path = vault_mount.transform.path
  name = "agent"
  transformations = [
    "nome_pessoa",
    "cpf",
    "cnpj",
    "endereco",
    "email",
    "telefone",
    "data",
    "agencia",
    "conta",
    "contrato",
    "valores",
    "produto",
    "ticket",
    "cnh",
    "cartao",
    "rg",
    "empresa",
    "pix",
    "outros"
  ]
}

#Templates
