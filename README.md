# terraform-vault-transform-cpf

Provisionamento via Terraform do **HashiCorp Vault Transform Secret Engine** para proteção de dados PII brasileiros, cobrindo FPE, masking e tokenização.

> ℹ️ O **Transform engine** é uma feature **Enterprise/HCP Vault** (Advanced Data Protection). Não está disponível no Vault OSS.

---

## O que este repositório configura

### FPE e Masking (`transformations_fpe_masking.tf`)

Transformações format-preserving reversíveis e mascaramento sobre dados formatados:

| Transformação | Tipo | Comportamento |
|---|---|---|
| `cpf` | FPE | Não-determinístico (`tweak_source=generated`) |
| `cnpj` | FPE | Determinístico (`tweak_source=internal`) |
| `email` | FPE | Não-determinístico, só transforma local-part |
| `telefone` | FPE | Não-determinístico |
| `conta` | FPE | Determinístico, preserva últimos dígitos |
| `agencia` | Masking | Máscara fixa `##` |
| `data` | FPE | Determinístico, formato `DD/MM/YYYY` |
| `rg` | FPE | Determinístico |
| `cnh` | FPE | Não-determinístico |
| `cartao` | FPE | Não-determinístico (builtin/creditcardnumber) |

### Tokenização (`modules/vault_tokenization/`)

Tokens opacos armazenados em PostgreSQL, um store por tipo de dado:

| Transformação | Convergente | Store |
|---|---|---|
| `nome_pessoa` | ✅ | `nome_pessoa_store` |
| `endereco` | ❌ | `endereco_store` |
| `valores` | ❌ | `valores_store` |
| `contrato` | ❌ | `contrato_store` |
| `produto` | ❌ | `produto_store` |
| `ticket` | ❌ | `ticket_store` |
| `pix` | ✅ | `pix_store` |
| `empresa` | ✅ | `empresa_store` |
| `outros` | ✅ | `outros_store` |

> Convergente = mesmo valor sempre gera o mesmo token (determinístico).

---

## Estrutura do repositório

```
.
├── main.tf                        # vault_mount (path: org, type: transform)
├── role.tf                        # vault_transform_role (role: agent)
├── variables.tf                   # Todas as variáveis de entrada
├── transformation_templates.tf    # Templates regex (CPF, CNPJ, email, telefone, etc.)
├── transformations_fpe_masking.tf # Transformações FPE e masking
├── tokenization.tf                # Chamada dos módulos rds e vault_tokenization
├── policy.tf                      # Vault policy para encode
├── misc.tf                        # Configurações globais do Vault (audit)
│
├── modules/
│   ├── rds/                       # AWS RDS PostgreSQL (opcional)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── vault_tokenization/        # Stores, schemas e transformações de tokenização
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── example/                       # Exemplos isolados de cada tipo de transformação
```

---

## Pré-requisitos

- **Vault Enterprise** ou **HCP Vault** com Transform habilitado na licença
- Token Vault com permissões em `sys/mounts/*` e `org/*`
- **Terraform** v1.5+
- **PostgreSQL** acessível pelo Vault (para tokenização)
  - Dois usuários: um de runtime (DML) e um DDL (para inicialização do schema)

---

## Variáveis

### Banco de dados (tokenização)

| Variável | Descrição | Default |
|---|---|---|
| `create_rds` | Provisiona RDS AWS automaticamente | `false` |
| `db_host` | Host do PostgreSQL (quando `create_rds = false`) | `""` |
| `db_port` | Porta | `5432` |
| `db_name` | Nome do banco | `"tokens"` |
| `db_user` | Usuário de runtime (DML) | — |
| `db_password` | Senha do usuário de runtime | — |
| `ddl_user` | Usuário DDL para inicialização do schema | — |
| `ddl_password` | Senha do usuário DDL | — |

### RDS (somente quando `create_rds = true`)

| Variável | Descrição | Default |
|---|---|---|
| `rds_vpc_id` | ID da VPC | — |
| `rds_subnet_ids` | IDs das subnets (mínimo 2) | — |
| `rds_instance_class` | Classe da instância | `db.t3.small` |
| `rds_identifier` | Identificador da instância | `vault-tokenization-db` |
| `rds_allowed_cidr_blocks` | CIDRs com acesso à porta 5432 | `[]` |
| `rds_allowed_security_group_ids` | Security groups com acesso | `[]` |
| `rds_multi_az` | Habilitar Multi-AZ | `false` |
| `rds_deletion_protection` | Proteção contra deleção | `true` |

---

## Quick start

### 1. Configurar o ambiente

```bash
export VAULT_ADDR="https://<seu-vault>:8200"
export VAULT_TOKEN="<token-admin>"
```

### 2. Inicializar

```bash
terraform init
```

### 3. Configurar o banco (escolha um modo)

**Modo A — banco externo existente:**
```hcl
# terraform.tfvars
create_rds   = false
db_host      = "meu-postgres.exemplo.com"
db_user      = "vault_runtime"
db_password  = "..."
ddl_user     = "vault_ddl"
ddl_password = "..."
```

**Modo B — subir RDS junto:**
```hcl
# terraform.tfvars
create_rds      = true
rds_vpc_id      = "vpc-xxxxxxxx"
rds_subnet_ids  = ["subnet-aaa", "subnet-bbb"]
db_user         = "vault_runtime"
db_password     = "..."
ddl_user        = "vault_ddl"
ddl_password    = "..."
```

### 4. Aplicar

```bash
terraform apply
```

---

## Exemplos de uso

O mount path é `org` e a role é `agent`.

### FPE via Vault CLI

```bash
# Encode CPF
vault write org/encode/agent transformation=cpf value="123.456.789-09"

# Decode CPF
vault write org/decode/agent transformation=cpf value="<valor-encodado>"

# Encode CNPJ
vault write org/encode/agent transformation=cnpj value="12.345.678/0001-90"

# Masking agência (irreversível)
vault write org/encode/agent transformation=agencia value="1234"
```

### Tokenização via Vault CLI

```bash
# Tokenizar nome de pessoa
vault write org/encode/agent transformation=nome_pessoa value="João da Silva"

# Detokenizar
vault write org/decode/agent transformation=nome_pessoa value="<token>"

# Tokenizar chave PIX
vault write org/encode/agent transformation=pix value="joao@exemplo.com"
```

### Via cURL

```bash
# Encode
curl -sS -H "X-Vault-Token: $VAULT_TOKEN" \
  -X POST "$VAULT_ADDR/v1/org/encode/agent" \
  -d '{"value":"123.456.789-09","transformation":"cpf"}' | jq .

# Decode
curl -sS -H "X-Vault-Token: $VAULT_TOKEN" \
  -X POST "$VAULT_ADDR/v1/org/decode/agent" \
  -d '{"value":"<encoded>","transformation":"cpf"}' | jq .
```

---

## Teardown

```bash
terraform destroy
```

---

## Referências

- [Vault Transform Secret Engine (Enterprise)](https://developer.hashicorp.com/vault/docs/secrets/transform)
- [Terraform Vault Provider — Transform resources](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/transform_transformation)
- [LGPD — Lei Geral de Proteção de Dados](https://www.gov.br/cidadania/pt-br/acesso-a-informacao/lgpd)
