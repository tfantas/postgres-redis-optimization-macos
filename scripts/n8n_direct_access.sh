#!/bin/bash

echo "🔍 Analisando configuração atual do n8n..."
echo ""

# Verificar usuários sem senha
echo "📊 Usuários no banco:"
/usr/local/opt/postgresql@15/bin/psql -U odin -d n8n_eternal -c "SELECT email, password IS NULL as no_password FROM public.user;" 2>/dev/null

echo ""
echo "🔓 Como os usuários não têm senha, o problema pode ser:"
echo ""
echo "1. O container 'claude-n8n-eternal' tem autenticação customizada"
echo "2. Está usando LDAP/SAML ao invés de senha local"
echo "3. Tem algum middleware de autenticação"
echo ""

# Verificar configurações do container
echo "🐳 Configurações do container atual:"
docker inspect claude-n8n-eternal | grep -E "(N8N_AUTH|N8N_BASIC|N8N_USER|LDAP|SAML)" | head -10

echo ""
echo "💡 SOLUÇÃO DIRETA:"
echo ""
echo "Como os usuários não têm senha no banco, você pode:"
echo ""
echo "1. Usar o email existente: claude@aix.local"
echo "2. Deixar a senha em branco no formulário"
echo "3. Ou clicar em 'Esqueci a senha' se disponível"
echo ""
echo "Se ainda pedir senha, o container está com autenticação externa (LDAP/SAML)."
echo ""
echo "🔧 Alternativa: Criar novo usuário com senha conhecida:"
echo ""

# Criar script SQL para novo usuário
cat > /tmp/create_n8n_user.sql << 'SQL'
-- Criar usuário admin com senha 'admin123'
INSERT INTO public.user (
    id,
    email, 
    "firstName", 
    "lastName", 
    password,
    "createdAt", 
    "updatedAt",
    "globalRoleId"
)
VALUES (
    gen_random_uuid(),
    'admin@localhost',
    'Admin',
    'Local',
    '$2a$10$MqVHHBxF8TlPUO1bPDE3jud5xnD1H1JlW8uzL5vRwxFbpQs5wC0s6', -- admin123
    NOW(),
    NOW(),
    (SELECT id FROM public.role WHERE name = 'owner' AND scope = 'global' LIMIT 1)
)
ON CONFLICT (email) 
DO UPDATE SET 
    password = '$2a$10$MqVHHBxF8TlPUO1bPDE3jud5xnD1H1JlW8uzL5vRwxFbpQs5wC0s6',
    "updatedAt" = NOW();

-- Verificar
SELECT email, password IS NOT NULL as has_password FROM public.user WHERE email = 'admin@localhost';
SQL

echo "Deseja criar usuário admin@localhost com senha admin123? (s/n)"
read -r response

if [[ "$response" =~ ^[Ss]$ ]]; then
    echo "🔨 Criando usuário..."
    /usr/local/opt/postgresql@15/bin/psql -U odin -d n8n_eternal -f /tmp/create_n8n_user.sql
    echo ""
    echo "✅ Usuário criado!"
    echo ""
    echo "📧 Email: admin@localhost"
    echo "🔑 Senha: admin123"
    echo ""
    echo "🌐 Acesse: http://localhost:5679"
fi