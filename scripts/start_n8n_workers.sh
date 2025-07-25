#!/bin/bash

echo "🚀 Iniciando workers do n8n..."
echo ""

# Número de workers
WORKERS=${1:-4}

echo "📊 Iniciando $WORKERS workers..."

for i in $(seq 1 $WORKERS); do
    echo "🔧 Iniciando worker $i..."
    
    docker run -d \
      --name n8n-worker-$i \
      --restart unless-stopped \
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
      -e N8N_CONCURRENCY_PRODUCTION_LIMIT=25 \
      -e N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true \
      -e N8N_RUNNERS_ENABLED=true \
      -v ~/.n8n:/home/node/.n8n \
      n8nio/n8n worker
      
    sleep 2
done

echo ""
echo "✅ $WORKERS workers iniciados!"
echo ""
echo "📊 Status dos containers:"
docker ps | grep n8n