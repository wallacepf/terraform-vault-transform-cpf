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

> Transformações com `tweak_source=generated` requerem o campo `tweak` retornado no encode para realizar o decode.

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
├── tokenization.tf                # Módulos rds e vault_tokenization
├── actions.tf                     # Action para criação do usuário do Vault no banco
├── outputs.tf                     # Outputs (rds_endpoint)
├── policy.tf                      # Vault policy para encode
├── misc.tf                        # Configurações globais do Vault (audit)
│
├── modules/
│   ├── rds/                       # AWS RDS PostgreSQL (opcional, create_rds = true)
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
- **Terraform** >= 1.14.0 (Actions support)
- **PostgreSQL** acessível pelo Vault (para tokenização)
- **`psql`** instalado no host que executa o Terraform (necessário apenas se usar a action `create_vault_user`)

---

## Permissionamento no banco (banco externo)

Quando `create_rds = false`, o usuário e o banco devem ser provisionados externamente. O Vault utiliza o mesmo usuário para duas operações distintas com requisitos diferentes:

### Inicialização do schema (`/stores/:name/schema`)

Chamado uma única vez pelo Terraform para criar as tabelas de tokenização. O usuário precisa de:

```sql
-- Acesso ao banco
GRANT CONNECT ON DATABASE <db_name> TO <vault_user>;

-- Permissão para criar as tabelas no schema
GRANT USAGE, CREATE ON SCHEMA public TO <vault_user>;
```

> A documentação oficial do Vault permite o uso de um usuário DDL exclusivo para este endpoint, separado do usuário de runtime. Neste módulo, o mesmo usuário é utilizado para ambas as operações por simplicidade.

### Operação em runtime (`/stores/:name`)

Utilizado pelo Vault em cada operação de tokenização/detokenização. Conforme a [documentação oficial do Vault](https://developer.hashicorp.com/vault/api-docs/secret/transform#create-update-tokenization-store):

> *"The database user configured here should only have permission to SELECT, INSERT, and UPDATE rows in the tables."*

O usuário precisa de:

```sql
-- Acesso ao banco
GRANT CONNECT ON DATABASE <db_name> TO <vault_user>;

-- Acesso às tabelas criadas pelo schema init
GRANT USAGE ON SCHEMA public TO <vault_user>;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO <vault_user>;

-- Garantir acesso a tabelas criadas futuramente
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE ON TABLES TO <vault_user>;
```

### Setup completo em um único usuário

Se optar por um único usuário para ambas as operações (abordagem deste módulo):

```sql
CREATE USER vault_user WITH PASSWORD 'senha-segura';
GRANT CONNECT ON DATABASE tokens TO vault_user;
GRANT USAGE, CREATE ON SCHEMA public TO vault_user;
```

> Como o usuário é dono das tabelas que cria via schema init, ele automaticamente tem SELECT, INSERT e UPDATE sobre elas — sem necessidade de grants adicionais.

### Criação do usuário via action (invocação manual)

Independente do modo (`create_rds = true` ou `false`), o usuário pode ser criado via action invocada manualmente:

```bash
terraform apply -invoke=action.local_command.create_vault_user
```

Isso conecta ao banco com `db_admin_user` e aplica exatamente o setup de permissões acima para `db_user`. Requer `psql` instalado e acesso de rede ao banco.

> A action **não é disparada automaticamente** em nenhum `terraform apply`. Ela deve ser invocada explicitamente quando necessário.

---

## Variáveis

### Banco de dados (tokenização)

| Variável | Descrição | Default |
|---|---|---|
| `create_rds` | Provisiona RDS AWS automaticamente | `false` |
| `db_host` | Host do PostgreSQL (quando `create_rds = false`) | `""` |
| `db_port` | Porta | `5432` |
| `db_name` | Nome do banco | `"tokens"` |
| `db_user` | Usuário do Vault no PostgreSQL | — |
| `db_password` | Senha do usuário do Vault | — |
| `db_sslmode` | SSL mode (`require` em produção, `disable` para testes) | `"require"` |
| `db_admin_user` | Usuário master/admin (obrigatório quando `create_rds = true`) | `""` |
| `db_admin_password` | Senha do usuário admin | `""` |

> **`db_user` / `db_password`** — comportamento por cenário:
> 1. `create_rds = false` → credenciais de um usuário já existente no banco externo
> 2. `create_rds = true`, action não invocada → credenciais a serem criadas manualmente
> 3. `create_rds = true`, action invocada → usuário criado automaticamente com as permissões acima

### RDS (somente quando `create_rds = true`)

| Variável | Descrição | Default |
|---|---|---|
| `rds_vpc_id` | ID da VPC | `""` |
| `rds_subnet_ids` | IDs das subnets (mínimo 2) | `[]` |
| `rds_instance_class` | Classe da instância | `db.t3.micro` |
| `rds_identifier` | Identificador da instância | `vault-tokenization-db` |
| `rds_allowed_cidr_blocks` | CIDRs com acesso à porta 5432 | `[]` |
| `rds_publicly_accessible` | Endpoint público (somente para testes) | `false` |
| `aws_region` | Região AWS | `us-east-1` |

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
db_name      = "tokens"
db_user      = "vault_user"
db_password  = "senha-segura"
db_sslmode   = "require"
```
> O usuário `vault_user` deve existir no banco com as permissões descritas em [Permissionamento no banco](#permissionamento-no-banco-banco-externo).

**Modo B — provisionar RDS na AWS:**
```hcl
# terraform.tfvars
create_rds              = true
rds_vpc_id              = "vpc-xxxxxxxx"
rds_subnet_ids          = ["subnet-aaa", "subnet-bbb"]
rds_allowed_cidr_blocks = ["10.0.0.0/8"]
db_admin_user           = "postgres"
db_admin_password       = "admin-senha"
db_user                 = "vault_user"
db_password             = "senha-segura"
db_name                 = "tokens"
db_sslmode              = "require"
```

### 4. Aplicar

```bash
terraform apply
```

### 5. Criar o usuário no banco (opcional)

Se optar pela criação automática do usuário via action:

```bash
terraform apply -invoke=action.local_command.create_vault_user
```

> Requer `psql` instalado e acesso de rede ao banco. Para o Modo B, garanta que `rds_allowed_cidr_blocks` inclua o IP do host que executa o Terraform e que `rds_publicly_accessible = true` (apenas para testes).

---

## Validação

Com o Vault configurado, valide as transformações manualmente via CLI:

```bash
# Tokenização (decode direto, sem tweak)
vault write org/encode/agent transformation=nome_pessoa value="João Silva"
vault write org/decode/agent transformation=nome_pessoa value="<token>"

# FPE com tweak interno (decode direto)
vault write org/encode/agent transformation=cnpj value="12.345.678/0001-90"
vault write org/decode/agent transformation=cnpj value="<encoded>"

# FPE com tweak gerado (cpf, email, telefone, cnh, cartao)
vault write -format=json org/encode/agent transformation=cpf value="123.456.789-00" \
  | jq '{encoded: .data.encoded_value, tweak: .data.tweak}'
vault write org/decode/agent transformation=cpf value="<encoded>" tweak="<tweak>"
```

> Transformações com `tweak_source=generated` (cpf, email, telefone, cnh, cartao) requerem o `tweak` retornado no encode para realizar o decode.

---

## Exemplos de uso

O mount path é `org` e a role é `agent`.

### FPE com tweak interno (decode direto)

```bash
vault write org/encode/agent transformation=cnpj value="12.345.678/0001-90"
vault write org/decode/agent transformation=cnpj value="<encoded>"
```

### FPE com tweak gerado (decode requer tweak)

```bash
# Encode — salve o tweak retornado
vault write -format=json org/encode/agent transformation=cpf value="123.456.789-00" \
  | jq '{encoded: .data.encoded_value, tweak: .data.tweak}'

# Decode — passe o tweak junto
vault write org/decode/agent transformation=cpf \
  value="<encoded>" \
  tweak="<tweak>"
```

### Tokenização

```bash
# Tokenizar
vault write org/encode/agent transformation=nome_pessoa value="João Silva"

# Detokenizar (token é auto-suficiente, não precisa de tweak)
vault write org/decode/agent transformation=nome_pessoa value="<token>"
```

### Via cURL

```bash
curl -sS -H "X-Vault-Token: $VAULT_TOKEN" \
  -X POST "$VAULT_ADDR/v1/org/encode/agent" \
  -d '{"value":"12.345.678/0001-90","transformation":"cnpj"}' | jq .
```

---

## Teardown

```bash
terraform destroy
```

---

## Referências

- [Vault Transform Secret Engine (Enterprise)](https://developer.hashicorp.com/vault/docs/secrets/transform)
- [Vault Tokenization — Storage](https://developer.hashicorp.com/vault/docs/secrets/transform/tokenization#storage)
- [Vault API — Tokenization Store](https://developer.hashicorp.com/vault/api-docs/secret/transform#create-update-tokenization-store)
- [Terraform Vault Provider — Transform resources](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/transform_transformation)
- [LGPD — Lei Geral de Proteção de Dados](https://www.gov.br/cidadania/pt-br/acesso-a-informacao/lgpd)
