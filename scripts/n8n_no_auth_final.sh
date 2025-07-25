#!/bin/bash

echo "🚀 Iniciando n8n com configuração otimizada"
echo ""
echo "⚠️  NOTA: n8n 1.103.1 não suporta desabilitar autenticação completamente"
echo "   Credenciais serão criadas automaticamente para acesso rápido"
echo ""

# Verificar serviços
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

# Verificar banco
if /usr/local/opt/postgresql@15/bin/psql -U odin -lqt | cut -d \| -f 1 | grep -qw n8n_eternal; then
    echo "✅ Banco n8n_eternal existe"
else
    echo "❌ Criando banco n8n_eternal..."
    /usr/local/opt/postgresql@15/bin/createdb -U odin n8n_eternal
fi

# Parar container anterior se existir
echo ""
echo "🧹 Limpando containers anteriores..."
docker stop n8n-native 2>/dev/null
docker rm n8n-native 2>/dev/null

echo ""
echo "🐳 Iniciando n8n com configuração otimizada..."
echo ""

# Criar diretório se não existir
mkdir -p ~/.n8n

# Iniciar n8n com configuração que funciona na 1.103.1
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
  -e N8N_USER_MANAGEMENT_DISABLED=false \
  -e N8N_PUBLIC_API_DISABLED=false \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n:1.103.1

echo "⏳ Aguardando n8n iniciar..."
sleep 15

# Verificar se iniciou
if curl -s http://localhost:5678 > /dev/null 2>&1; then
    echo ""
    echo "✅ n8n iniciado com sucesso!"
    echo ""
    
    # Criar arquivo com credenciais para acesso rápido
    cat > ~/.n8n/quick_access.txt << 'EOF'
🔐 ACESSO RÁPIDO AO N8N
======================

URL: http://localhost:5678

Email: admin@localhost
Senha: n8n123

DICA: Salve como bookmark no navegador para acesso direto!

Para pular login após entrar:
1. Faça login uma vez
2. Bookmark direto: http://localhost:5678/workflows
3. O cookie de sessão manterá você logado

EOF

    echo "📋 Credenciais de acesso salvas em: ~/.n8n/quick_access.txt"
    echo ""
    echo "🌐 Acesse: http://localhost:5678"
    echo "📧 Email: admin@localhost"
    echo "🔑 Senha: n8n123"
    echo ""
    echo "💡 Dica: Após fazer login, salve http://localhost:5678/workflows como bookmark"
    echo ""
    echo "📊 Dashboards disponíveis:"
    echo "   - n8n: http://localhost:5678"
    echo "   - Dashboard BullMQ: http://localhost:3001"
    echo "   - Bull Board: http://localhost:3001/admin/queues"
    echo ""
    echo "🔧 Para adicionar workers:"
    echo "   ./start_n8n_workers.sh"
    
    # Tentar criar usuário automaticamente
    echo ""
    echo "🔓 Tentando criar usuário para acesso rápido..."
    sleep 5
    
    # SQL para criar usuário
    /usr/local/opt/postgresql@15/bin/psql -U odin -d n8n_eternal << 'EOF' 2>/dev/null
-- Verificar se tabelas existem
DO $$ 
BEGIN
    -- Aguardar tabelas serem criadas
    PERFORM pg_sleep(5);
    
    -- Verificar se role existe
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'role') THEN
        -- Inserir usuário se não existir
        INSERT INTO public.user (
            email, 
            "firstName", 
            "lastName", 
            password,
            "createdAt", 
            "updatedAt", 
            "globalRoleId"
        )
        SELECT 
            'admin@localhost',
            'Admin',
            'Local',
            '$2a$10$5QrnuPfV0YzNGJCZx0C0Ue4Ww0kJPQZJfkEfJpYG6a2/Ao1wVG8K2', -- n8n123
            NOW(),
            NOW(),
            (SELECT id FROM public.role WHERE name = 'owner' AND scope = 'global' LIMIT 1)
        WHERE NOT EXISTS (
            SELECT 1 FROM public.user WHERE email = 'admin@localhost'
        );
        
        RAISE NOTICE 'Usuário criado/verificado com sucesso';
    ELSE
        RAISE NOTICE 'Tabelas ainda não criadas, execute novamente em alguns segundos';
    END IF;
END $$;
EOF

    if [ $? -eq 0 ]; then
        echo "✅ Usuário de acesso rápido configurado!"
    else
        echo "⚠️  Usuário será criado no primeiro acesso"
    fi
    
else
    echo "❌ Erro ao iniciar n8n. Verificando logs..."
    docker logs n8n-native
fi

echo ""
echo "📝 Para mais informações sobre warnings, veja:"
echo "   docs/n8n_warnings_explained.md"