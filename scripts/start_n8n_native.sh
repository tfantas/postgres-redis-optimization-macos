#!/bin/bash

echo "🚀 Iniciando n8n com PostgreSQL e Redis nativos otimizados..."
echo ""
echo "📊 Configuração:"
echo "   PostgreSQL: localhost:5432 (16GB RAM)"
echo "   Redis: localhost:6379 (12GB RAM)"
echo "   Database: n8n_eternal"
echo ""

# Verificar se os serviços estão rodando
echo "🔍 Verificando serviços..."

# PostgreSQL
if /usr/local/opt/postgresql@15/bin/psql -U odin -d postgres -c "SELECT 1" > /dev/null 2>&1; then
    echo "✅ PostgreSQL está rodando"
else
    echo "❌ PostgreSQL não está rodando. Iniciando..."
    brew services start postgresql@15
    sleep 3
fi

# Redis
if redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis está rodando"
else
    echo "❌ Redis não está rodando. Iniciando..."
    brew services start redis
    sleep 3
fi

# Verificar se o banco n8n_eternal existe
if /usr/local/opt/postgresql@15/bin/psql -U odin -lqt | cut -d \| -f 1 | grep -qw n8n_eternal; then
    echo "✅ Banco n8n_eternal existe"
else
    echo "❌ Criando banco n8n_eternal..."
    /usr/local/opt/postgresql@15/bin/createdb -U odin n8n_eternal
fi

echo ""
echo "🐳 Iniciando n8n com Docker usando serviços nativos..."
echo ""

# Iniciar n8n principal
docker run -d \
  --name n8n-native \
  --restart unless-stopped \
  -p 5678:5678 \
  -e DB_TYPE=postgresdb \
  -e DB_POSTGRESDB_HOST=host.docker.internal \
  -e DB_POSTGRESDB_PORT=5432 \
  -e DB_POSTGRESDB_DATABASE=n8n_eternal \
  -e DB_POSTGRESDB_USER=odin \
  -e DB_POSTGRESDB_SCHEMA=public \
  -e EXECUTIONS_MODE=queue \
  -e QUEUE_BULL_REDIS_HOST=host.docker.internal \
  -e QUEUE_BULL_REDIS_PORT=6379 \
  -e QUEUE_BULL_REDIS_DB=1 \
  -e N8N_DIAGNOSTICS_ENABLED=false \
  -e N8N_PERSONALIZATION_ENABLED=false \
  -e GENERIC_TIMEZONE=America/Sao_Paulo \
  -e N8N_METRICS=true \
  -e N8N_CONCURRENCY_PRODUCTION_LIMIT=100 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n:1.103.1

echo "⏳ Aguardando n8n iniciar..."
sleep 10

# Verificar se iniciou
if curl -s http://localhost:5678 > /dev/null 2>&1; then
    echo ""
    echo "✅ n8n iniciado com sucesso!"
    echo ""
    echo "🌐 Acesse: http://localhost:5678"
    echo ""
    echo "📊 Monitoramento:"
    echo "   - n8n: http://localhost:5678"
    echo "   - Dashboard BullMQ: http://localhost:3001"
    echo "   - Bull Board: http://localhost:3001/admin/queues"
    echo ""
    echo "🔧 Para adicionar workers:"
    echo "   ./start_n8n_workers.sh"
else
    echo "❌ Erro ao iniciar n8n. Verificando logs..."
    docker logs n8n-native
fi