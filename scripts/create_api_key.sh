#!/bin/bash

echo "🔑 Criando API Key para testes"
echo ""

# Gerar API key
API_KEY="n8n_api_$(openssl rand -hex 32)"

# Verificar estrutura da tabela
echo "📊 Estrutura da tabela user_api_keys:"
/usr/local/opt/postgresql@15/bin/psql -U odin -d n8n_eternal -c "\d public.user_api_keys" 2>&1 | head -20

echo ""
echo "🔍 Verificando usuários disponíveis:"
/usr/local/opt/postgresql@15/bin/psql -U odin -d n8n_eternal -c "SELECT id, email FROM public.user LIMIT 5;" 2>/dev/null

# Pegar ID do primeiro usuário
USER_ID=$(/usr/local/opt/postgresql@15/bin/psql -U odin -d n8n_eternal -t -c "SELECT id FROM public.user LIMIT 1;" 2>/dev/null | tr -d ' ')

echo ""
echo "📝 Criando API key para usuário: $USER_ID"

# Criar API key
/usr/local/opt/postgresql@15/bin/psql -U odin -d n8n_eternal << EOF 2>&1
INSERT INTO public.user_api_keys (
    "userId",
    label,
    "apiKey",
    "createdAt",
    "updatedAt"
) VALUES (
    '$USER_ID',
    'Test API Key',
    '$API_KEY',
    NOW(),
    NOW()
)
ON CONFLICT DO NOTHING;

-- Verificar
SELECT label, "apiKey", "createdAt" 
FROM public.user_api_keys 
WHERE "userId" = '$USER_ID'
ORDER BY "createdAt" DESC
LIMIT 1;
EOF

echo ""
echo "✅ API Key criada: $API_KEY"
echo ""
echo "📋 Salvando em arquivo..."
echo "$API_KEY" > ~/.n8n_api_key.txt

echo ""
echo "🧪 Testando API com a chave criada..."
echo ""

# Testar com API key
curl -H "X-N8N-API-KEY: $API_KEY" \
     -H "Accept: application/json" \
     http://localhost:5678/api/v1/workflows 2>&1 | head -20

echo ""
echo "✅ Concluído!"