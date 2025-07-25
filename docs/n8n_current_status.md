# 📊 Status Atual do n8n

## ✅ n8n ESTÁ RODANDO!

### Acesso
- **URL**: http://localhost:5679
- **Status**: Funcionando perfeitamente
- **Modo**: Docker com 4 workers

### Arquitetura Atual

```
┌─────────────────────────────────────────────────┐
│                   DOCKER                         │
├─────────────────────────────────────────────────┤
│  n8n (porta 5679)                               │
│    ├── Worker 1                                 │
│    ├── Worker 2                                 │
│    ├── Worker 3                                 │
│    └── Worker 4                                 │
│                                                 │
│  PostgreSQL (claude-postgres)                   │
│    └── Banco: n8n_eternal                       │
│                                                 │
│  Redis (claude-redis)                           │
│    └── Filas do n8n                            │
└─────────────────────────────────────────────────┘
                    ↕️
┌─────────────────────────────────────────────────┐
│                  NATIVO                         │
├─────────────────────────────────────────────────┤
│  PostgreSQL (porta 5432)                        │
│    ├── postgres (16GB RAM)                      │
│    ├── n8n_eternal (migrado)                    │
│    ├── aix_memory                               │
│    └── claude_memory                            │
│                                                 │
│  Redis (porta 6379)                             │
│    ├── 12GB RAM                                 │
│    ├── BullMQ queues                            │
│    └── 8 I/O threads                            │
└─────────────────────────────────────────────────┘
```

## Situação

1. **n8n em Docker**: Usando PostgreSQL e Redis do Docker
2. **BullMQ nativo**: Usando PostgreSQL e Redis nativos otimizados
3. **Dados migrados**: O banco `n8n_eternal` foi copiado para o PostgreSQL nativo

## Para Migrar n8n para Serviços Nativos

Se quiser migrar o n8n para usar os serviços nativos otimizados:

```bash
# 1. Parar containers atuais
docker stop claude-n8n-eternal

# 2. Executar n8n com configuração nativa
docker run -it --rm \
  --name n8n-native \
  -p 5678:5678 \
  -e DB_TYPE=postgresdb \
  -e DB_POSTGRESDB_HOST=host.docker.internal \
  -e DB_POSTGRESDB_PORT=5432 \
  -e DB_POSTGRESDB_DATABASE=n8n_eternal \
  -e DB_POSTGRESDB_USER=odin \
  -e QUEUE_BULL_REDIS_HOST=host.docker.internal \
  -e QUEUE_BULL_REDIS_PORT=6379 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n
```

## Integração com BullMQ

O n8n pode criar jobs no BullMQ nativo através de nodes HTTP:

1. **HTTP Request Node**
   - URL: http://host.docker.internal:3001/api/add-job
   - Method: POST
   - Body: `{ "queue": "email", "data": { ... } }`

2. **Code Node** (JavaScript)
   ```javascript
   const Redis = require('ioredis');
   const redis = new Redis({
     host: 'host.docker.internal',
     port: 6379
   });
   
   // Adicionar job diretamente
   await redis.rpush('bull:email:wait', JSON.stringify({
     name: 'send-email',
     data: $json,
     opts: {}
   }));
   ```

## URLs de Acesso

- **n8n**: http://localhost:5679 ✅
- **Dashboard BullMQ**: http://localhost:3001 ✅
- **Bull Board**: http://localhost:3001/admin/queues ✅