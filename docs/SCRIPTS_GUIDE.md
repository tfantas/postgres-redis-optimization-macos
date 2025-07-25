# 📜 Guia Completo dos Scripts

## 📁 Estrutura dos Scripts

```
scripts/
├── optimization/          # Scripts de otimização
├── migration/            # Scripts de migração
├── n8n/                  # Scripts do n8n
├── testing/              # Scripts de teste
└── maintenance/          # Scripts de manutenção
```

## 🔧 Scripts de Otimização

### 1. apply_postgresql_optimization.sh

**Propósito**: Aplica todas as otimizações de performance no PostgreSQL.

**Uso**:
```bash
./scripts/apply_postgresql_optimization.sh
```

**O que faz**:
- Detecta quantidade de RAM do sistema
- Calcula valores otimizados (25% para shared_buffers)
- Backup da configuração original
- Aplica mais de 30 parâmetros otimizados
- Reinicia o PostgreSQL

**Parâmetros aplicados**:
- Memória: shared_buffers, effective_cache_size, work_mem
- Performance: parallel workers, random_page_cost
- WAL: wal_buffers, checkpoint settings
- Logging: slow queries, connections, locks

### 2. optimize_redis_full.sh

**Propósito**: Configura Redis com todas otimizações de performance.

**Uso**:
```bash
./scripts/optimize_redis_full.sh
```

**O que faz**:
- Configura 12GB de memória máxima
- Habilita 8 I/O threads
- Configura persistência AOF + RDB
- Otimiza políticas de eviction
- Define slow log

**Configurações principais**:
- maxmemory 12gb
- io-threads 8
- appendonly yes
- save 3600 1 300 100 60 10000

## 🔄 Scripts de Migração

### 3. migrate_postgres_docker_to_native.sh

**Propósito**: Migra dados do PostgreSQL Docker para nativo.

**Uso**:
```bash
./scripts/migrate_postgres_docker_to_native.sh [container_name]
```

**Processo**:
1. Faz dump do container Docker
2. Para o container
3. Restaura no PostgreSQL nativo
4. Verifica integridade

### 4. migrate_redis_docker_to_native.sh

**Propósito**: Migra dados do Redis Docker para nativo.

**Uso**:
```bash
./scripts/migrate_redis_docker_to_native.sh [container_name]
```

**Processo**:
1. Salva snapshot do Redis Docker
2. Copia arquivo dump.rdb
3. Restaura no Redis nativo
4. Verifica chaves migradas

## 🚀 Scripts do n8n

### 5. start_n8n_clean.sh

**Propósito**: Inicia n8n limpo com configurações otimizadas.

**Uso**:
```bash
./scripts/start_n8n_clean.sh
```

**Funcionalidades**:
- Verifica serviços nativos (PostgreSQL/Redis)
- Cria container com configurações corretas
- Usa volume ~/n8n_data para persistência
- Exibe logs de inicialização

### 6. start_n8n_workers.sh

**Propósito**: Adiciona workers para processamento paralelo.

**Uso**:
```bash
./scripts/start_n8n_workers.sh [número_de_workers]
# Exemplo: ./scripts/start_n8n_workers.sh 4
```

**O que faz**:
- Inicia N workers do n8n
- Cada worker em container separado
- Conecta ao Redis para queue
- Nomeia workers sequencialmente

### 7. n8n_direct_access.sh

**Propósito**: Analisa usuários e configurações do n8n.

**Uso**:
```bash
./scripts/n8n_direct_access.sh
```

**Informações fornecidas**:
- Lista usuários no banco
- Mostra configurações do container
- Oferece criar usuário admin
- Explica limitações de autenticação

## 🧪 Scripts de Teste

### 8. health_check.sh

**Propósito**: Verifica saúde completa do sistema.

**Uso**:
```bash
./scripts/health_check.sh
```

**Verificações**:
- ✅ Serviços nativos (PostgreSQL/Redis)
- ✅ Containers Docker
- ✅ Recursos do sistema
- ✅ Endpoints e dashboards
- ✅ Estatísticas operacionais
- ✅ Segurança

**Saída**: Resumo colorido com total de verificações.

### 9. test_n8n_api.sh

**Propósito**: Testa endpoints básicos da API n8n.

**Uso**:
```bash
./scripts/test_n8n_api.sh
```

**Testes realizados**:
- GET /healthz
- GET /rest/settings
- POST /rest/login
- GET /rest/workflows

### 10. test_api_complete.sh

**Propósito**: Teste completo da API com API key.

**Uso**:
```bash
./scripts/test_api_complete.sh
```

**Funcionalidades**:
- Lista workflows
- Executa workflows
- Cria novos workflows
- Monitora logs em tempo real

### 11. create_api_key.sh

**Propósito**: Cria API key para acesso programático.

**Uso**:
```bash
./scripts/create_api_key.sh
```

**O que faz**:
- Gera API key segura
- Insere no banco de dados
- Salva em ~/.n8n_api_key.txt
- Testa a API key criada

## 🛠️ Scripts de Manutenção

### 12. backup_postgres.sh (a criar)

**Propósito**: Backup automatizado do PostgreSQL.

**Uso sugerido**:
```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$HOME/backups/postgres"
mkdir -p $BACKUP_DIR

# Backup completo
pg_dump -U odin -Fc n8n_eternal > "$BACKUP_DIR/n8n_eternal_$DATE.dump"

# Manter apenas últimos 7 dias
find $BACKUP_DIR -name "*.dump" -mtime +7 -delete
```

### 13. cleanup_old_executions.sh (a criar)

**Propósito**: Limpa execuções antigas do n8n.

**Uso sugerido**:
```bash
#!/bin/bash
# Deletar execuções com mais de 30 dias
psql -U odin -d n8n_eternal -c "
DELETE FROM execution_entity 
WHERE finished_at < NOW() - INTERVAL '30 days';"

# VACUUM para recuperar espaço
psql -U odin -d n8n_eternal -c "VACUUM ANALYZE;"
```

## 📊 Scripts Utilitários

### 14. monitor_resources.sh (a criar)

**Propósito**: Monitora uso de recursos em tempo real.

**Funcionalidades sugeridas**:
- CPU/RAM por processo
- Conexões ativas PostgreSQL
- Memória Redis
- Jobs em queue

### 15. benchmark_system.sh (a criar)

**Propósito**: Executa benchmarks de performance.

**Testes sugeridos**:
- pgbench para PostgreSQL
- redis-benchmark para Redis
- API stress test para n8n

## 🔐 Variáveis de Ambiente

Todos os scripts respeitam estas variáveis:

```bash
# PostgreSQL
export PGUSER="odin"
export PGDATABASE="n8n_eternal"
export PGHOST="localhost"
export PGPORT="5432"

# Redis
export REDIS_HOST="localhost"
export REDIS_PORT="6379"

# n8n
export N8N_HOST="localhost"
export N8N_PORT="5678"
```

## 📝 Convenções dos Scripts

1. **Shebang**: Todos começam com `#!/bin/bash`
2. **Set options**: Usam `set -euo pipefail` para segurança
3. **Logs**: Prefixo com emoji para facilitar leitura
4. **Cores**: Verde ✅, Vermelho ❌, Amarelo ⚠️
5. **Verificações**: Sempre verificam pré-requisitos
6. **Cleanup**: Limpam recursos em caso de erro

## 🚨 Tratamento de Erros

Todos os scripts incluem:

```bash
# Trap para cleanup em caso de erro
trap cleanup EXIT

cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo "❌ Script falhou com código: $exit_code"
    fi
}
```

## 📅 Agendamento com Cron

Exemplo de crontab para manutenção:

```cron
# Backup diário às 2:00 AM
0 2 * * * /path/to/backup_postgres.sh

# Health check a cada hora
0 * * * * /path/to/health_check.sh

# Limpeza semanal aos domingos
0 3 * * 0 /path/to/cleanup_old_executions.sh
```

## 💡 Dicas de Uso

1. **Sempre verifique logs**: `tail -f /usr/local/var/log/*.log`
2. **Use health_check.sh**: Antes de reportar problemas
3. **Backup antes de migrar**: Segurança em primeiro lugar
4. **Teste em dev primeiro**: Nunca execute direto em produção
5. **Documente mudanças**: Adicione comentários nos scripts

Este guia será atualizado conforme novos scripts forem adicionados ao projeto.