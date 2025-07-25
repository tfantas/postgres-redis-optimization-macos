# 📋 Referência de Configurações

## PostgreSQL 15 - Configurações Aplicadas

### Localização dos Arquivos
- **Config principal**: `/usr/local/var/postgresql@15/postgresql.conf`
- **Logs**: `/usr/local/var/log/postgresql@15.log`
- **Data directory**: `/usr/local/var/postgresql@15`

### Parâmetros de Memória

| Parâmetro | Valor | Descrição | Cálculo |
|-----------|-------|-----------|---------|
| shared_buffers | 16GB | Buffer compartilhado | 25% de 64GB RAM |
| effective_cache_size | 48GB | Cache estimado do OS | 75% de 64GB RAM |
| work_mem | 256MB | Memória por operação | RAM/256 |
| maintenance_work_mem | 2GB | Para VACUUM, CREATE INDEX | RAM/32 |
| wal_buffers | 64MB | Buffer para WAL | 3% de shared_buffers |

### Parâmetros de Performance

| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| max_parallel_workers | 12 | Workers paralelos totais |
| max_parallel_workers_per_gather | 8 | Workers por query |
| max_parallel_maintenance_workers | 4 | Workers para manutenção |
| effective_io_concurrency | 0 | Desabilitado no macOS |
| random_page_cost | 1.1 | Custo de acesso aleatório (SSD) |

### Write-Ahead Logging (WAL)

| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| wal_level | replica | Nível de log para replicação |
| min_wal_size | 2GB | Tamanho mínimo do WAL |
| max_wal_size | 8GB | Tamanho máximo do WAL |
| wal_compression | on | Compressão do WAL |
| archive_mode | off | Arquivamento desabilitado |

### Checkpoints

| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| checkpoint_timeout | 15min | Intervalo entre checkpoints |
| checkpoint_completion_target | 0.9 | Taxa de conclusão |
| checkpoint_warning | 30s | Aviso se checkpoint demorar |

### Logging

| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| log_destination | stderr | Destino dos logs |
| logging_collector | on | Coletor de logs ativo |
| log_directory | log | Diretório de logs |
| log_filename | postgresql-%Y-%m-%d_%H%M%S.log | Formato do arquivo |
| log_rotation_age | 1d | Rotação diária |
| log_rotation_size | 100MB | Rotação por tamanho |
| log_min_duration_statement | 100ms | Log queries > 100ms |
| log_checkpoints | on | Log de checkpoints |
| log_connections | on | Log de conexões |
| log_disconnections | on | Log de desconexões |
| log_lock_waits | on | Log de esperas por lock |
| log_temp_files | 0 | Log todos arquivos temporários |

### Estatísticas

| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| track_activities | on | Rastrear atividades |
| track_counts | on | Rastrear contadores |
| track_io_timing | on | Rastrear tempo de I/O |
| track_wal_io_timing | on | Rastrear tempo de WAL I/O |
| track_functions | all | Rastrear todas funções |
| stats_temp_directory | pg_stat_tmp | Diretório temporário |

## Redis 8.0.3 - Configurações Aplicadas

### Localização dos Arquivos
- **Config principal**: `/usr/local/etc/redis.conf`
- **Logs**: Saída padrão (brew services)
- **Data directory**: `/usr/local/var/db/redis/`

### Configurações de Memória

| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| maxmemory | 12gb | Limite máximo de memória |
| maxmemory-policy | allkeys-lru | Política de eviction |
| maxmemory-samples | 5 | Amostras para LRU |

### I/O Threads

| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| io-threads | 8 | Número de I/O threads |
| io-threads-do-reads | yes | Threads para leitura |

### Persistência

| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| save | 3600 1 300 100 60 10000 | Snapshots automáticos |
| stop-writes-on-bgsave-error | yes | Parar escrita em erro |
| rdbcompression | yes | Compressão RDB |
| rdbchecksum | yes | Checksum RDB |
| dbfilename | dump.rdb | Nome do arquivo RDB |
| appendonly | yes | AOF habilitado |
| appendfilename | appendonly.aof | Nome do arquivo AOF |
| appendfsync | everysec | Sync a cada segundo |
| no-appendfsync-on-rewrite | no | Sync durante rewrite |
| auto-aof-rewrite-percentage | 100 | Rewrite em 100% |
| auto-aof-rewrite-min-size | 64mb | Tamanho mínimo para rewrite |

### Network

| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| bind | 127.0.0.1 -::1 | IPs de bind |
| protected-mode | yes | Modo protegido |
| port | 6379 | Porta padrão |
| tcp-backlog | 511 | Backlog TCP |
| timeout | 0 | Sem timeout |
| tcp-keepalive | 300 | Keepalive 5 min |

### Limites

| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| databases | 16 | Número de databases |
| maxclients | 10000 | Clientes máximos |

### Slow Log

| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| slowlog-log-slower-than | 10000 | Log comandos > 10ms |
| slowlog-max-len | 128 | Tamanho máximo do log |

### Advanced

| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| hash-max-listpack-entries | 512 | Entradas max em hash |
| hash-max-listpack-value | 64 | Valor max em hash |
| list-max-listpack-size | -2 | Tamanho max de lista |
| list-compress-depth | 0 | Profundidade de compressão |
| set-max-intset-entries | 512 | Entradas max em set |
| zset-max-listpack-entries | 128 | Entradas max em zset |
| zset-max-listpack-value | 64 | Valor max em zset |
| hll-sparse-max-bytes | 3000 | Bytes max para HLL |
| stream-node-max-bytes | 4096 | Bytes max para stream |
| stream-node-max-entries | 100 | Entradas max em stream |

## n8n - Variáveis de Ambiente

### Database

| Variável | Valor | Descrição |
|----------|-------|-----------|
| DB_TYPE | postgresdb | Tipo de banco |
| DB_POSTGRESDB_HOST | host.docker.internal | Host do PostgreSQL |
| DB_POSTGRESDB_PORT | 5432 | Porta do PostgreSQL |
| DB_POSTGRESDB_DATABASE | n8n_eternal | Nome do banco |
| DB_POSTGRESDB_USER | odin | Usuário do banco |
| DB_POSTGRESDB_SCHEMA | public | Schema padrão |

### Queue

| Variável | Valor | Descrição |
|----------|-------|-----------|
| EXECUTIONS_MODE | queue | Modo de execução |
| QUEUE_BULL_REDIS_HOST | host.docker.internal | Host do Redis |
| QUEUE_BULL_REDIS_PORT | 6379 | Porta do Redis |
| QUEUE_BULL_REDIS_DB | 1 | Database do Redis |

### Configurações Gerais

| Variável | Valor | Descrição |
|----------|-------|-----------|
| N8N_METRICS | true | Métricas habilitadas |
| N8N_DIAGNOSTICS_ENABLED | false | Diagnósticos desabilitados |
| N8N_PERSONALIZATION_ENABLED | false | Personalização desabilitada |
| GENERIC_TIMEZONE | America/Sao_Paulo | Timezone |

### Volumes

| Host | Container | Descrição |
|------|-----------|-----------|
| ~/n8n_data | /home/node/.n8n | Dados persistentes |

## BullMQ - Configurações

### Redis Connection

```javascript
{
  host: 'localhost',
  port: 6379,
  db: 0,
  maxRetriesPerRequest: 3,
  enableReadyCheck: true,
  lazyConnect: false
}
```

### Queue Options

```javascript
{
  defaultJobOptions: {
    removeOnComplete: 100,
    removeOnFail: 1000,
    attempts: 3,
    backoff: {
      type: 'exponential',
      delay: 2000
    }
  }
}
```

### Worker Options

```javascript
{
  concurrency: 10,
  limiter: {
    max: 100,
    duration: 1000
  }
}
```

## Portas Utilizadas

| Serviço | Porta | Descrição |
|---------|-------|-----------|
| PostgreSQL | 5432 | Banco de dados principal |
| Redis | 6379 | Cache e filas |
| n8n | 5678 | Interface web |
| BullMQ Dashboard | 3001 | Dashboard de filas |

## Recursos do Sistema

### Alocação de Memória (64GB Total)

| Componente | RAM Alocada | Percentual |
|------------|-------------|------------|
| PostgreSQL | 16GB | 25% |
| Redis | 12GB | 18.75% |
| Sistema/Apps | 36GB | 56.25% |

### CPU

| Componente | Cores/Threads | Uso Estimado |
|------------|---------------|--------------|
| PostgreSQL | 12 workers | Variável |
| Redis | 8 I/O threads | ~10% |
| n8n | 4 workers | ~20% |

Esta documentação serve como referência completa para todas as configurações aplicadas no sistema.