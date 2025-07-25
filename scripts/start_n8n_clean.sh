#!/bin/bash

echo "🧹 Iniciando n8n limpo e otimizado"
echo ""

# Verificar serviços nativos
echo "🔍 Verificando serviços nativos..."
if ! /usr/local/opt/postgresql@15/bin/psql -U odin -d postgres -c "SELECT 1" > /dev/null 2>&1; then
    echo "❌ PostgreSQL não está rodando"
    exit 1
fi
echo "✅ PostgreSQL rodando"

if ! redis-cli ping > /dev/null 2>&1; then
    echo "❌ Redis não está rodando"
    exit 1
fi
echo "✅ Redis rodando"

# Verificar banco
if ! /usr/local/opt/postgresql@15/bin/psql -U odin -lqt | cut -d \| -f 1 | grep -qw n8n_eternal; then
    echo "❌ Banco n8n_eternal não existe"
    exit 1
fi
echo "✅ Banco n8n_eternal existe"

echo ""
echo "🐳 Iniciando n8n com configuração limpa..."
echo ""

# Iniciar n8n
docker run -d \
  --name n8n-clean \
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
  -v ~/n8n_data:/home/node/.n8n \
  n8nio/n8n:1.103.1

echo "⏳ Aguardando n8n iniciar (30 segundos)..."
sleep 30

# Verificar logs
echo ""
echo "📋 Logs do n8n:"
echo "==============="
docker logs n8n-clean 2>&1 | tail -50

echo ""
echo "🔍 Verificando status..."
if curl -s http://localhost:5678 > /dev/null 2>&1; then
    echo "✅ n8n iniciado com sucesso!"
    echo ""
    echo "🌐 Acesse: http://localhost:5678"
    echo ""
    echo "📧 Use o usuário criado:"
    echo "   Email: admin@localhost"
    echo "   Senha: admin123"
else
    echo "❌ n8n não respondeu. Verificando logs completos..."
    docker logs n8n-clean
fi