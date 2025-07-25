#!/bin/bash

echo "🧪 Teste Completo da API n8n"
echo "============================"
echo ""

API_KEY="n8n_api_e9804ba4d41638eff236b0d6b8c1c53741f97d0cb8741acedb0cd1982a83858e"
BASE_URL="http://localhost:5678/api/v1"

# Função para fazer requisições e monitorar logs
test_api() {
    local method=$1
    local endpoint=$2
    local data=$3
    local desc=$4
    
    echo "📡 $desc"
    echo "   Método: $method"
    echo "   Endpoint: $endpoint"
    
    # Capturar logs antes da requisição
    local log_before=$(docker logs n8n-clean 2>&1 | wc -l)
    
    if [ -n "$data" ]; then
        response=$(curl -s -X $method "$BASE_URL$endpoint" \
            -H "X-N8N-API-KEY: $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$data" \
            -w "\nHTTP_STATUS:%{http_code}")
    else
        response=$(curl -s -X $method "$BASE_URL$endpoint" \
            -H "X-N8N-API-KEY: $API_KEY" \
            -H "Accept: application/json" \
            -w "\nHTTP_STATUS:%{http_code}")
    fi
    
    http_status=$(echo "$response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
    body=$(echo "$response" | sed -n '1,/HTTP_STATUS:/p' | sed '$d')
    
    echo "   Status: $http_status"
    echo "   Resposta: $(echo $body | jq -r '.' 2>/dev/null || echo $body)"
    
    # Capturar novos logs
    echo "   📋 Novos logs:"
    docker logs n8n-clean 2>&1 | tail -n +$((log_before + 1)) | grep -v "GET /rest/push" | head -5
    echo ""
}

# 1. Listar workflows
test_api "GET" "/workflows" "" "Listar todos os workflows"

# 2. Obter detalhes de um workflow específico
WORKFLOW_ID=$(curl -s -X GET "$BASE_URL/workflows" \
    -H "X-N8N-API-KEY: $API_KEY" \
    -H "Accept: application/json" | jq -r '.data[0].id' 2>/dev/null)

if [ -n "$WORKFLOW_ID" ] && [ "$WORKFLOW_ID" != "null" ]; then
    test_api "GET" "/workflows/$WORKFLOW_ID" "" "Obter detalhes do workflow $WORKFLOW_ID"
    
    # 3. Executar workflow
    test_api "POST" "/workflows/$WORKFLOW_ID/execute" '{}' "Executar workflow $WORKFLOW_ID"
fi

# 4. Listar execuções
test_api "GET" "/executions" "" "Listar execuções"

# 5. Criar um workflow simples
WORKFLOW_JSON='{
  "name": "Test Workflow API",
  "nodes": [
    {
      "parameters": {},
      "name": "Start",
      "type": "n8n-nodes-base.start",
      "typeVersion": 1,
      "position": [250, 300]
    }
  ],
  "connections": {},
  "active": false,
  "settings": {}
}'

test_api "POST" "/workflows" "$WORKFLOW_JSON" "Criar novo workflow"

# 6. Listar credenciais
test_api "GET" "/credentials" "" "Listar credenciais"

# 7. Obter estatísticas
echo "📊 Verificando estatísticas finais..."
echo ""

# Contar workflows
WORKFLOW_COUNT=$(curl -s -X GET "$BASE_URL/workflows" \
    -H "X-N8N-API-KEY: $API_KEY" \
    -H "Accept: application/json" | jq '.data | length' 2>/dev/null)

echo "   Total de workflows: $WORKFLOW_COUNT"

# Verificar execuções
EXEC_COUNT=$(curl -s -X GET "$BASE_URL/executions" \
    -H "X-N8N-API-KEY: $API_KEY" \
    -H "Accept: application/json" | jq '.data | length' 2>/dev/null)

echo "   Total de execuções: $EXEC_COUNT"

echo ""
echo "🔍 Logs finais do container (erros/warnings):"
docker logs n8n-clean 2>&1 | grep -E "(error|Error|ERROR|warning|Warning|WARNING)" | tail -10

echo ""
echo "✅ Testes de API concluídos!"