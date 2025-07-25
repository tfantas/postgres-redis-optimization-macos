#!/bin/bash

echo "🔓 Configurando n8n para pular tela de login..."
echo ""

# Verificar se PostgreSQL está acessível
if ! /usr/local/opt/postgresql@15/bin/psql -U odin -d n8n_eternal -c "SELECT 1" > /dev/null 2>&1; then
    echo "❌ PostgreSQL não está acessível. Verifique se está rodando."
    exit 1
fi

echo "📝 Criando usuário padrão sem senha..."

# Criar ou atualizar usuário padrão
/usr/local/opt/postgresql@15/bin/psql -U odin -d n8n_eternal << 'EOF'
-- Verificar estrutura da tabela user
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'user' 
ORDER BY ordinal_position;

-- Criar usuário se não existir
INSERT INTO public.user (email, "firstName", "lastName", "createdAt", "updatedAt", "globalRoleId")
SELECT 
    'admin@localhost',
    'Admin',
    'Local',
    NOW(),
    NOW(),
    (SELECT id FROM public.role WHERE name = 'owner' AND scope = 'global' LIMIT 1)
WHERE NOT EXISTS (
    SELECT 1 FROM public.user WHERE email = 'admin@localhost'
);

-- Remover senha do usuário
UPDATE public.user 
SET password = NULL 
WHERE email = 'admin@localhost';

-- Verificar resultado
SELECT id, email, "firstName", "lastName" 
FROM public.user 
WHERE email = 'admin@localhost';
EOF

echo ""
echo "✅ Usuário configurado!"
echo ""
echo "📋 Instruções para acessar sem senha:"
echo ""
echo "1. Acesse: http://localhost:5678"
echo "2. Na tela de login, use:"
echo "   Email: admin@localhost"
echo "   Senha: (deixe vazio ou qualquer coisa)"
echo ""
echo "3. Ou adicione este bookmark para pular login direto:"
echo "   http://localhost:5678/workflows"
echo ""
echo "💡 Dica: Após entrar, você pode criar workflows normalmente!"