# Análise Técnica Detalhada - PostgreSQL e Redis

## PostgreSQL 15.13 - Configuração Atual

### ⚠️ PROBLEMAS CRÍTICOS DE PERFORMANCE

#### 1. **Memória MUITO MAL CONFIGURADA**
- **shared_buffers**: 128MB (deveria ser 16GB para 64GB RAM)
- **effective_cache_size**: 4GB (deveria ser 48GB)
- **work_mem**: 4MB (deveria ser 256MB)
- **maintenance_work_mem**: 64MB (deveria ser 2GB)

#### 2. **Paralelismo SUB-UTILIZADO**
- **max_parallel_workers_per_gather**: 2 (deveria ser 4-6)
- **max_parallel_workers**: 8 (deveria ser 16 para 16 CPUs)
- **max_parallel_maintenance_workers**: 2 (deveria ser 4)

#### 3. **Configurações para SSD não otimizadas**
- **random_page_cost**: 4 (deveria ser 1.1 para SSD)
- **effective_io_concurrency**: 0 (deveria ser 200 para SSD NVMe)

### 📊 Extensões e Features

#### Extensões Instaladas:
- ✅ plpgsql (linguagem procedural)
- ❌ pgvector (NÃO INSTALADO - necessário para vector search)
- ❌ pg_stat_statements (NÃO INSTALADO - análise de queries)
- ❌ pg_trgm (NÃO INSTALADO - busca fuzzy)

#### Para instalar pgvector:
```bash
# Via Homebrew
brew install pgvector

# No banco de dados
CREATE EXTENSION vector;
```

### 🚀 Script de Otimização Completo

```bash
#!/bin/bash
# salvar como optimize_postgres_full.sh

# Aplicar todas as otimizações
cat >> /usr/local/var/postgresql@15/postgresql.conf << EOF

# === OTIMIZAÇÕES PARA 64GB RAM E 16 CPUs ===
# Memória
shared_buffers = 16GB
effective_cache_size = 48GB
work_mem = 256MB
maintenance_work_mem = 2GB
wal_buffers = 512MB

# Paralelismo
max_parallel_workers_per_gather = 4
max_parallel_workers = 16
max_parallel_maintenance_workers = 4
parallel_leader_participation = on
parallel_setup_cost = 100  # Reduzido de 1000
parallel_tuple_cost = 0.01  # Reduzido de 0.1

# SSD NVMe
random_page_cost = 1.1
effective_io_concurrency = 200
maintenance_io_concurrency = 200

# Checkpoint
checkpoint_completion_target = 0.9
max_wal_size = 4GB
min_wal_size = 1GB

# Estatísticas
default_statistics_target = 200
track_io_timing = on

# Autovacuum
autovacuum_max_workers = 4
autovacuum_naptime = 10s
EOF

brew services restart postgresql@15
```

## Redis 8.0.3 - Configuração Atual

### 📊 Status Atual
- **Versão**: 8.0.3 (última versão!)
- **Memória**: Usando apenas 945KB de 64GB disponíveis
- **maxmemory**: 0 (sem limite - PERIGOSO!)
- **Módulos**: vectorset instalado (suporte a vetores!)

### ⚠️ Problemas de Configuração

1. **Sem limite de memória** - pode consumir toda RAM
2. **Sem persistência AOF** - apenas RDB
3. **Sem configuração para BullMQ**

### 🚀 Otimizações Recomendadas

```bash
# Adicionar ao /usr/local/etc/redis.conf

# Limite de memória (12GB de 64GB)
maxmemory 12gb
maxmemory-policy allkeys-lru

# Persistência híbrida
appendonly yes
appendfsync everysec

# Otimizações para BullMQ
tcp-backlog 511
timeout 0
tcp-keepalive 300

# Lazy freeing para performance
lazyfree-lazy-eviction yes
lazyfree-lazy-expire yes
lazyfree-lazy-server-del yes

# Threads I/O (para 16 CPUs)
io-threads 8
io-threads-do-reads yes
```

## BullMQ e Filas

### PostgreSQL para Filas
```sql
-- Criar tabela otimizada para queue
CREATE TABLE job_queue (
  id BIGSERIAL PRIMARY KEY,
  queue_name VARCHAR(255) NOT NULL,
  payload JSONB NOT NULL,
  status VARCHAR(50) DEFAULT 'pending',
  priority INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  processed_at TIMESTAMP,
  completed_at TIMESTAMP,
  error TEXT,
  attempts INT DEFAULT 0
);

-- Índices para performance
CREATE INDEX idx_queue_status ON job_queue(queue_name, status, priority DESC, created_at);
CREATE INDEX idx_queue_processing ON job_queue(processed_at) WHERE status = 'processing';

-- Função para pegar próximo job
CREATE OR REPLACE FUNCTION get_next_job(p_queue_name VARCHAR)
RETURNS job_queue AS $$
DECLARE
  v_job job_queue;
BEGIN
  SELECT * INTO v_job
  FROM job_queue
  WHERE queue_name = p_queue_name
    AND status = 'pending'
  ORDER BY priority DESC, created_at
  FOR UPDATE SKIP LOCKED
  LIMIT 1;
  
  IF FOUND THEN
    UPDATE job_queue 
    SET status = 'processing', 
        processed_at = NOW()
    WHERE id = v_job.id;
  END IF;
  
  RETURN v_job;
END;
$$ LANGUAGE plpgsql;
```

### Redis com BullMQ
```javascript
// Configuração otimizada para BullMQ
const Queue = require('bullmq').Queue;
const Worker = require('bullmq').Worker;

const queue = new Queue('myqueue', {
  connection: {
    host: 'localhost',
    port: 6379,
    maxRetriesPerRequest: null,
    enableReadyCheck: false,
    // Otimizações para performance
    enableOfflineQueue: false,
    connectTimeout: 10000
  },
  defaultJobOptions: {
    removeOnComplete: 1000,  // Manter últimos 1000 jobs completos
    removeOnFail: 5000,      // Manter últimos 5000 jobs falhados
    attempts: 3,
    backoff: {
      type: 'exponential',
      delay: 2000
    }
  }
});

// Worker com concorrência
const worker = new Worker('myqueue', async job => {
  // processar job
}, {
  connection: { /* mesma config */ },
  concurrency: 50,  // Processar 50 jobs simultaneamente
  limiter: {
    max: 100,
    duration: 1000  // Max 100 jobs por segundo
  }
});
```

## Comparação: PostgreSQL vs Redis para Filas

| Feature | PostgreSQL | Redis + BullMQ |
|---------|------------|----------------|
| Performance | ~1K jobs/sec | ~100K jobs/sec |
| Persistência | ACID completo | RDB/AOF |
| Queries complexas | ✅ SQL completo | ❌ Limitado |
| Prioridades | ✅ Flexível | ✅ Nativo |
| Delayed jobs | ✅ Com timestamp | ✅ Nativo |
| Rate limiting | ❌ Manual | ✅ Nativo |
| Dashboard | ❌ Precisa criar | ✅ Bull Board |
| Escalabilidade | Vertical | Horizontal (Redis Cluster) |

## Recomendações

1. **Para alta performance**: Use Redis + BullMQ
2. **Para consistência**: Use PostgreSQL
3. **Híbrido**: Redis para fila rápida, PostgreSQL para auditoria

## Comandos para Aplicar Otimizações

```bash
# 1. Otimizar PostgreSQL
/Users/odin/Projetos/2025/apply_postgresql_optimization.sh
brew services restart postgresql@15

# 2. Otimizar Redis
/Users/odin/Projetos/2025/optimize_redis.sh
brew services restart redis

# 3. Instalar pgvector
brew install pgvector
psql -U odin -d postgres -c "CREATE EXTENSION vector;"

# 4. Verificar performance
psql -U odin -c "SHOW shared_buffers;"
redis-cli CONFIG GET maxmemory
```