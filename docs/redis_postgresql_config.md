# Configuração Redis + PostgreSQL

## Status Atual ✅
- **PostgreSQL**: Rodando na porta 5432
- **Redis**: Rodando na porta 6379 (versão 8.0.2)

## Arquitetura de Cache com Redis + PostgreSQL

### 1. Cache de Consultas
Redis armazena resultados de queries pesadas do PostgreSQL:
```
PostgreSQL (Dados persistentes) 
    ↓
Redis (Cache temporário)
    ↓
Aplicação
```

### 2. Session Store
- PostgreSQL: Dados de usuários
- Redis: Sessões ativas

### 3. Queue/Jobs
- PostgreSQL: Jobs persistentes
- Redis: Fila de processamento

## Configurações de Conexão

### PostgreSQL
```
Host: localhost
Port: 5432
User: odin
Password: (vazio)
```

### Redis
```
Host: localhost
Port: 6379
Password: (vazio)
```

## Exemplo de Uso com Node.js

```javascript
// config/database.js
const { Client } = require('pg');
const redis = require('redis');

// PostgreSQL
const pgClient = new Client({
  host: 'localhost',
  port: 5432,
  user: 'odin',
  database: 'postgres'
});

// Redis
const redisClient = redis.createClient({
  host: 'localhost',
  port: 6379
});

module.exports = { pgClient, redisClient };
```

## Exemplo de Cache Pattern

```javascript
async function getUserWithCache(userId) {
  const cacheKey = `user:${userId}`;
  
  // 1. Verificar cache Redis
  const cached = await redisClient.get(cacheKey);
  if (cached) {
    return JSON.parse(cached);
  }
  
  // 2. Buscar no PostgreSQL
  const result = await pgClient.query(
    'SELECT * FROM users WHERE id = $1', 
    [userId]
  );
  
  // 3. Armazenar no cache (TTL: 1 hora)
  await redisClient.setex(
    cacheKey, 
    3600, 
    JSON.stringify(result.rows[0])
  );
  
  return result.rows[0];
}
```

## Exemplo com Python

```python
import psycopg2
import redis
import json

# PostgreSQL
pg_conn = psycopg2.connect(
    host="localhost",
    database="postgres",
    user="odin"
)

# Redis
redis_client = redis.Redis(
    host='localhost', 
    port=6379, 
    decode_responses=True
)

def get_user_with_cache(user_id):
    cache_key = f"user:{user_id}"
    
    # Verificar cache
    cached = redis_client.get(cache_key)
    if cached:
        return json.loads(cached)
    
    # Buscar no PostgreSQL
    cursor = pg_conn.cursor()
    cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
    user = cursor.fetchone()
    
    # Armazenar no cache
    redis_client.setex(
        cache_key, 
        3600, 
        json.dumps(user)
    )
    
    return user
```

## Comandos Úteis

### Redis CLI
```bash
# Conectar ao Redis
redis-cli

# Ver todas as chaves
KEYS *

# Ver valor de uma chave
GET key_name

# Definir valor com expiração
SETEX key_name 3600 "value"

# Limpar todo o cache
FLUSHALL

# Monitorar comandos em tempo real
MONITOR
```

### Monitoramento
```bash
# Status do Redis
redis-cli INFO stats

# Memória usada
redis-cli INFO memory

# Clientes conectados
redis-cli CLIENT LIST
```

## Performance Tips

1. **Use TTL apropriado**: Evite cache eterno
2. **Invalide cache**: Ao atualizar dados no PostgreSQL
3. **Use Redis Pub/Sub**: Para invalidação distribuída
4. **Configure maxmemory**: Para evitar uso excessivo de RAM

### Configuração recomendada para Redis (redis.conf):
```
maxmemory 4gb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
```