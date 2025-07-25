#!/bin/bash

echo "🧪 Testando API do n8n"
echo "===================="
echo ""

BASE_URL="http://localhost:5678"

# Função para fazer requisições com logs
api_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    local desc=$4
    
    echo "📡 $desc"
    echo "   Método: $method"
    echo "   Endpoint: $endpoint"
    if [ -n "$data" ]; then
        echo "   Dados: $data"
    fi
    echo ""
    
    if [ -n "$data" ]; then
        response=$(curl -s -X $method "$BASE_URL$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data" \
            -w "\nHTTP_STATUS:%{http_code}")
    else
        response=$(curl -s -X $method "$BASE_URL$endpoint" \
            -H "Accept: application/json" \
            -w "\nHTTP_STATUS:%{http_code}")
    fi
    
    http_status=$(echo "$response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
    body=$(echo "$response" | sed -n '1,/HTTP_STATUS:/p' | sed '$d')
    
    echo "   Status: $http_status"
    echo "   Resposta: $body"
    echo ""
    
    # Verificar logs do container após cada requisição
    echo "   📋 Logs do container:"
    docker logs n8n-clean 2>&1 | tail -5 | grep -v "GET /rest/push" | head -3
    echo ""
    echo "   ---"
    echo ""
}

# 1. Testar endpoint de saúde
api_request "GET" "/healthz" "" "Verificar saúde da aplicação"

# 2. Testar endpoint de versão
api_request "GET" "/rest/settings" "" "Obter configurações públicas"

# 3. Tentar acessar workflows sem autenticação
api_request "GET" "/rest/workflows" "" "Listar workflows (sem auth)"

# 4. Testar login com diferentes formatos
echo "🔐 Testando formatos de login..."
echo ""

# Formato 1: emailOrLdapLoginId
api_request "POST" "/rest/login" \
    '{"emailOrLdapLoginId":"admin@localhost","password":"admin123"}' \
    "Login formato 1"

# Formato 2: email
api_request "POST" "/rest/login" \
    '{"email":"admin@localhost","password":"admin123"}' \
    "Login formato 2"

# 5. Verificar endpoints da API
echo "📚 Verificando endpoints disponíveis..."
echo ""

endpoints=(
    "/rest/users"
    "/rest/workflows"
    "/rest/executions"
    "/rest/credentials"
    "/rest/tags"
    "/api/v1/workflows"
    "/rest/metrics"
    "/rest/push"
)

for endpoint in "${endpoints[@]}"; do
    echo -n "Testando $endpoint... "
    status=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$endpoint")
    echo "Status: $status"
done

echo ""
echo "🔍 Verificando logs finais do container..."
docker logs n8n-clean 2>&1 | grep -E "(error|Error|ERROR|warning|Warning)" | tail -10

echo ""
echo "✅ Testes de API concluídos!"