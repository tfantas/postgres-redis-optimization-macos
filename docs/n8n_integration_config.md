# 🔗 Integração n8n com PostgreSQL e Redis

## Status Atual ✅

### PostgreSQL
- **Banco**: `n8n_eternal` 
- **Usuário**: `odin`
- **Tabelas**: 35+ tabelas do n8n
- **Performance**: Otimizado com 16GB RAM

### Redis
- **Uso**: Cache e filas do n8n
- **Memória**: 12GB disponíveis
- **I/O Threads**: 8

## Configuração do n8n

### 1. Arquivo de Configuração
Criar `/Users/odin/.n8n/config`:

```json
{
  "database": {
    "type": "postgresdb",
    "postgresdb": {
      "host": "localhost",
      "port": 5432,
      "database": "n8n_eternal",
      "user": "odin",
      "password": "",
      "schema": "public"
    }
  },
  "executions": {
    "mode": "queue",
    "queue": {
      "bull": {
        "redis": {
          "host": "localhost",
          "port": 6379,
          "db": 0
        }
      }
    },
    "pruneData": true,
    "pruneDataMaxAge": 336
  },
  "generic": {
    "timezone": "America/Sao_Paulo"
  }
}
```

### 2. Variáveis de Ambiente
```bash
export N8N_DATABASE_TYPE=postgresdb
export N8N_DATABASE_POSTGRES_HOST=localhost
export N8N_DATABASE_POSTGRES_PORT=5432
export N8N_DATABASE_POSTGRES_DATABASE=n8n_eternal
export N8N_DATABASE_POSTGRES_USER=odin
export N8N_DATABASE_POSTGRES_PASSWORD=

# Redis para filas
export N8N_QUEUE_MODE=redis
export N8N_REDIS_HOST=localhost
export N8N_REDIS_PORT=6379

# Performance
export N8N_CONCURRENCY_PRODUCTION_LIMIT=100
export N8N_PAYLOAD_SIZE_MAX=256
```

### 3. Iniciar n8n
```bash
# Modo produção com Redis
n8n start --tunnel

# Ou com Docker (usando serviços nativos)
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -e DB_TYPE=postgresdb \
  -e DB_POSTGRESDB_HOST=host.docker.internal \
  -e DB_POSTGRESDB_PORT=5432 \
  -e DB_POSTGRESDB_DATABASE=n8n_eternal \
  -e DB_POSTGRESDB_USER=odin \
  -e EXECUTIONS_MODE=queue \
  -e QUEUE_BULL_REDIS_HOST=host.docker.internal \
  -e QUEUE_BULL_REDIS_PORT=6379 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n
```

## Workflows de Exemplo

### 1. Monitor de Filas BullMQ
```json
{
  "name": "Monitor BullMQ",
  "nodes": [
    {
      "name": "Redis Get Stats",
      "type": "n8n-nodes-base.redis",
      "typeVersion": 1,
      "position": [250, 300],
      "credentials": {
        "redis": {
          "id": "1",
          "name": "Redis Local"
        }
      },
      "parameters": {
        "operation": "get",
        "key": "bull:*:stats"
      }
    }
  ]
}
```

### 2. Backup Automático PostgreSQL
```json
{
  "name": "Backup PostgreSQL",
  "nodes": [
    {
      "name": "Cron",
      "type": "n8n-nodes-base.cron",
      "typeVersion": 1,
      "position": [250, 300],
      "parameters": {
        "triggerTimes": {
          "item": [{
            "hour": 2,
            "minute": 0
          }]
        }
      }
    },
    {
      "name": "Execute Command",
      "type": "n8n-nodes-base.executeCommand",
      "typeVersion": 1,
      "position": [450, 300],
      "parameters": {
        "command": "pg_dump -U odin n8n_eternal > /backup/n8n_$(date +%Y%m%d).sql"
      }
    }
  ]
}
```

## Monitoramento

### Dashboard n8n
- URL: http://localhost:5678
- Métricas: http://localhost:5678/rest/metrics

### Verificar Filas no Redis
```bash
redis-cli
> KEYS bull:*
> INFO stats
```

### Verificar Execuções no PostgreSQL
```sql
-- Últimas execuções
SELECT id, workflow_id, status, started_at, finished_at 
FROM execution_entity 
ORDER BY started_at DESC 
LIMIT 10;

-- Estatísticas
SELECT status, COUNT(*) 
FROM execution_entity 
GROUP BY status;
```

## Performance Tips

1. **PostgreSQL**: Com 16GB de shared_buffers, suporta milhares de execuções
2. **Redis**: Com 12GB, pode armazenar milhões de jobs na fila
3. **Concorrência**: Configure `N8N_CONCURRENCY_PRODUCTION_LIMIT` baseado nos workers

## Integração com BullMQ

O n8n pode disparar jobs no BullMQ:

```javascript
// Node Function no n8n
const Queue = require('bullmq').Queue;

const emailQueue = new Queue('email', {
  connection: {
    host: 'localhost',
    port: 6379
  }
});

await emailQueue.add('send-notification', {
  to: items[0].json.email,
  subject: 'Workflow Completed'
});

return items;
```