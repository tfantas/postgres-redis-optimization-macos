#!/bin/bash

echo "🚀 Aplicando otimizações completas no Redis para BullMQ..."

# Backup da configuração atual
echo "📦 Fazendo backup da configuração atual..."
cp /usr/local/etc/redis.conf /usr/local/etc/redis.conf.backup.$(date +%Y%m%d_%H%M%S)

# Criar nova configuração otimizada
echo "⚙️  Criando configuração otimizada..."

cat > /usr/local/etc/redis.conf << 'EOF'
# Redis Configuration - Otimizado para 64GB RAM e BullMQ
# Gerado em: $(date)

# Network
bind 127.0.0.1 ::1
protected-mode yes
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 300

# Memória - 12GB de 64GB disponíveis
maxmemory 12gb
maxmemory-policy allkeys-lru

# Persistência híbrida (RDB + AOF)
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /usr/local/var/db/redis

# AOF para durabilidade
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# Performance
databases 16
hz 10
dynamic-hz yes

# I/O Threads (para 16 CPUs)
io-threads 8
io-threads-do-reads yes

# Lazy freeing (não bloqueia ao deletar chaves grandes)
lazyfree-lazy-eviction yes
lazyfree-lazy-expire yes
lazyfree-lazy-server-del yes
replica-lazy-flush yes

# Logging
loglevel notice
logfile /usr/local/var/log/redis.log
syslog-enabled no

# Slow log
slowlog-log-slower-than 10000
slowlog-max-len 128

# Client output buffer limits
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit replica 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60

# BullMQ Otimizações
# Permite mais clientes simultâneos
maxclients 10000

# Timeouts otimizados para jobs longos
timeout 0
tcp-keepalive 60

# Otimizações de Lua scripts (BullMQ usa muito Lua)
lua-time-limit 5000

# Compressão de listas (útil para filas)
list-compress-depth 1
list-max-ziplist-size -2

# Otimizações de hash (metadados de jobs)
hash-max-ziplist-entries 512
hash-max-ziplist-value 64

# Stream settings (BullMQ pode usar streams)
stream-node-max-bytes 4096
stream-node-max-entries 100

# Active rehashing
activerehashing yes

# Latency monitoring
latency-monitor-threshold 100

# Proteção contra OOM
oom-score-adj no
oom-score-adj-values 0 200 800

# TLS (desativado por padrão)
# port 0
# tls-port 6379

EOF

echo "✅ Configuração criada!"

# Reiniciar Redis
echo "🔄 Reiniciando Redis..."
brew services restart redis

sleep 3

# Verificar se está rodando
if redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis está rodando!"
    echo ""
    echo "📊 Configurações aplicadas:"
    echo "Memória máxima: $(redis-cli CONFIG GET maxmemory | tail -1)"
    echo "I/O Threads: $(redis-cli CONFIG GET io-threads | tail -1)"
    echo "Política de eviction: $(redis-cli CONFIG GET maxmemory-policy | tail -1)"
    echo ""
    
    # Testar performance
    echo "🧪 Testando performance..."
    redis-benchmark -t set,get -n 10000 -q
    
    echo ""
    echo "🎯 Redis otimizado para BullMQ com:"
    echo "   - 12GB de memória máxima"
    echo "   - 8 I/O threads"
    echo "   - Persistência híbrida (RDB + AOF)"
    echo "   - Lazy freeing ativado"
    echo "   - Otimizações para Lua scripts"
else
    echo "❌ Erro ao iniciar Redis. Verifique os logs em /usr/local/var/log/redis.log"
fi