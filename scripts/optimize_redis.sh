#!/bin/bash

echo "🚀 Otimizando Redis para trabalhar com PostgreSQL..."

# Backup da configuração atual
echo "📦 Fazendo backup da configuração atual..."
cp /usr/local/etc/redis.conf /usr/local/etc/redis.conf.backup.$(date +%Y%m%d_%H%M%S)

# Aplicar configurações otimizadas
echo "⚙️  Aplicando configurações otimizadas..."

# Adicionar configurações ao final do arquivo
cat >> /usr/local/etc/redis.conf << 'EOF'

# Otimizações para uso com PostgreSQL
# Configurado em: $(date)

# Limite de memória - 8GB para cache (de 64GB total)
maxmemory 8gb

# Política de remoção - Remove chaves menos usadas quando atingir limite
maxmemory-policy allkeys-lru

# Persistência - Salvar a cada 5 minutos se houver mudanças
save 300 10
save 60 10000

# Performance
tcp-backlog 511
timeout 0
tcp-keepalive 300

# Configurações de rede
bind 127.0.0.1 ::1
protected-mode yes
port 6379

# Logs
loglevel notice
logfile /usr/local/var/log/redis.log

# Otimizações de performance
databases 16
hz 10
dynamic-hz yes

# Lazy freeing (não bloqueia ao deletar chaves grandes)
lazyfree-lazy-eviction yes
lazyfree-lazy-expire yes
lazyfree-lazy-server-del yes
replica-lazy-flush yes

# Compressão de listas
list-compress-depth 1

# Cliente output buffer (para pub/sub)
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit replica 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60

EOF

echo "✅ Configurações aplicadas!"

# Reiniciar Redis
echo "🔄 Reiniciando Redis..."
brew services restart redis

sleep 2

# Verificar se está rodando
if redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis está rodando!"
    echo ""
    echo "📊 Configurações aplicadas:"
    redis-cli CONFIG GET maxmemory
    redis-cli CONFIG GET maxmemory-policy
    echo ""
    echo "🎯 Redis otimizado para cache com PostgreSQL!"
else
    echo "❌ Erro ao iniciar Redis. Verifique os logs em /usr/local/var/log/redis.log"
fi