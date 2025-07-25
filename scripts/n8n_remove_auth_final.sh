#!/bin/bash

echo "🔓 Removendo autenticação do n8n definitivamente"
echo ""

# Verificar PostgreSQL
if ! /usr/local/opt/postgresql@15/bin/psql -U odin -d n8n_eternal -c "SELECT 1" > /dev/null 2>&1; then
    echo "❌ Banco n8n_eternal não acessível"
    exit 1
fi

echo "📝 Removendo senhas de todos os usuários..."

# Remover senhas e atualizar configurações
/usr/local/opt/postgresql@15/bin/psql -U odin -d n8n_eternal << 'EOF'
-- Remover senhas de todos os usuários
UPDATE public.user SET password = NULL;

-- Verificar resultado
SELECT id, email, password IS NULL as no_password FROM public.user;
EOF

echo ""
echo "🐳 Parando container atual..."
docker stop claude-n8n-eternal 2>/dev/null

echo ""
echo "🚀 Iniciando n8n modificado sem autenticação..."

# Criar Dockerfile customizado
cat > /tmp/n8n-no-auth.Dockerfile << 'DOCKERFILE'
FROM n8nio/n8n:latest

# Script para bypass de autenticação
RUN echo '#!/bin/sh' > /custom-entrypoint.sh && \
    echo 'export N8N_AUTH_EXCLUDE_ENDPOINTS=".*"' >> /custom-entrypoint.sh && \
    echo 'export N8N_BASIC_AUTH_ACTIVE=false' >> /custom-entrypoint.sh && \
    echo 'export N8N_USER_MANAGEMENT_DISABLED=true' >> /custom-entrypoint.sh && \
    echo 'exec /docker-entrypoint.sh "$@"' >> /custom-entrypoint.sh && \
    chmod +x /custom-entrypoint.sh

ENTRYPOINT ["/custom-entrypoint.sh"]
DOCKERFILE

# Construir imagem
echo "🔨 Construindo imagem customizada..."
docker build -t n8n-no-auth:latest -f /tmp/n8n-no-auth.Dockerfile . 2>/dev/null

# Iniciar novo container
docker run -d \
  --name n8n-no-auth \
  --restart unless-stopped \
  -p 5681:5678 \
  -e DB_TYPE=postgresdb \
  -e DB_POSTGRESDB_HOST=host.docker.internal \
  -e DB_POSTGRESDB_PORT=5432 \
  -e DB_POSTGRESDB_DATABASE=n8n_eternal \
  -e DB_POSTGRESDB_USER=odin \
  -e DB_POSTGRESDB_SCHEMA=public \
  -e EXECUTIONS_MODE=regular \
  -e N8N_DIAGNOSTICS_ENABLED=false \
  -e N8N_PERSONALIZATION_ENABLED=false \
  -e GENERIC_TIMEZONE=America/Sao_Paulo \
  -v ~/.n8n:/home/node/.n8n \
  n8n-no-auth:latest

echo "⏳ Aguardando iniciar..."
sleep 10

# Verificar
if curl -s http://localhost:5681 > /dev/null 2>&1; then
    echo ""
    echo "✅ n8n iniciado SEM AUTENTICAÇÃO!"
    echo ""
    echo "🌐 Acesse: http://localhost:5681"
    echo "🎉 Sem necessidade de login!"
else
    echo "❌ Erro ao iniciar. Verificando logs..."
    docker logs n8n-no-auth
fi