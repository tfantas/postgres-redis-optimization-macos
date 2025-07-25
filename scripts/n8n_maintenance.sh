#!/bin/bash

echo "🔧 Manutenção do n8n"
echo "==================="
echo ""

# Função para colorir output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Verificar containers rodando
echo "📦 Verificando containers n8n..."
MAIN_CONTAINER=$(docker ps --filter "name=n8n-native" --format "{{.Names}}" | head -1)
WORKER_COUNT=$(docker ps --filter "name=n8n-worker" --format "{{.Names}}" | wc -l | tr -d ' ')

if [ -n "$MAIN_CONTAINER" ]; then
    echo -e "${GREEN}✅ n8n principal rodando${NC}"
else
    echo -e "${RED}❌ n8n principal não está rodando${NC}"
    echo "   Execute: ./scripts/start_n8n_native.sh"
fi

echo -e "👷 Workers rodando: ${WORKER_COUNT}"
if [ "$WORKER_COUNT" -lt 4 ]; then
    echo -e "${YELLOW}⚠️  Recomendado: 4 workers${NC}"
    echo "   Execute: ./scripts/start_n8n_workers.sh 4"
fi

# 2. Verificar warnings conhecidos
echo ""
echo "⚠️  Warnings conhecidos (não impedem funcionamento):"
echo ""

# Verificar logs do container principal
if [ -n "$MAIN_CONTAINER" ]; then
    echo "📋 Logs do n8n principal:"
    docker logs "$MAIN_CONTAINER" 2>&1 | grep -E "deprecation|WARNING" | tail -5 | while read line; do
        if [[ $line == *"N8N_RUNNERS_ENABLED"* ]]; then
            echo -e "${YELLOW}  - Task runners deprecated${NC}"
            echo "    → Será obrigatório em versão futura"
            echo "    → Aguardar correção na próxima versão"
        elif [[ $line == *"OFFLOAD_MANUAL_EXECUTIONS"* ]]; then
            echo -e "${YELLOW}  - Manual executions routing${NC}"
            echo "    → Workers processarão execuções manuais no futuro"
            echo "    → Considere aumentar memória dos workers"
        elif [[ $line == *"Permissions"* ]]; then
            echo -e "${YELLOW}  - Permissões de arquivo${NC}"
            echo "    → Execute: ./scripts/fix_n8n_permissions.sh"
        fi
    done
fi

# 3. Verificar conectividade
echo ""
echo "🌐 Verificando conectividade..."

# PostgreSQL
if /usr/local/opt/postgresql@15/bin/psql -U odin -d n8n_eternal -c "SELECT 1" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ PostgreSQL conectado (n8n_eternal)${NC}"
else
    echo -e "${RED}❌ PostgreSQL não acessível${NC}"
fi

# Redis
if redis-cli -n 1 ping > /dev/null 2>&1; then
    QUEUE_SIZE=$(redis-cli -n 1 LLEN bull:jobs:wait 2>/dev/null || echo "0")
    echo -e "${GREEN}✅ Redis conectado (DB 1) - Jobs na fila: $QUEUE_SIZE${NC}"
else
    echo -e "${RED}❌ Redis não acessível${NC}"
fi

# n8n Web UI
if curl -s http://localhost:5678 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ n8n Web UI acessível${NC}"
else
    echo -e "${RED}❌ n8n Web UI não acessível${NC}"
fi

# 4. Estatísticas
echo ""
echo "📊 Estatísticas:"

if [ -n "$MAIN_CONTAINER" ]; then
    # Uso de memória
    MEM_USAGE=$(docker stats --no-stream --format "{{.MemUsage}}" "$MAIN_CONTAINER" 2>/dev/null | head -1)
    echo "   Memória n8n: $MEM_USAGE"
    
    # Workflows ativos
    ACTIVE_WORKFLOWS=$(/usr/local/opt/postgresql@15/bin/psql -U odin -d n8n_eternal -t -c "SELECT COUNT(*) FROM workflow_entity WHERE active = true" 2>/dev/null | tr -d ' ')
    echo "   Workflows ativos: $ACTIVE_WORKFLOWS"
    
    # Execuções recentes
    RECENT_EXECS=$(/usr/local/opt/postgresql@15/bin/psql -U odin -d n8n_eternal -t -c "SELECT COUNT(*) FROM execution_entity WHERE started_at > NOW() - INTERVAL '1 hour'" 2>/dev/null | tr -d ' ')
    echo "   Execuções (última hora): $RECENT_EXECS"
fi

# 5. Ações recomendadas
echo ""
echo "🎯 Ações recomendadas:"

ACTIONS_NEEDED=false

# Verificar se precisa corrigir permissões
if [ -f ~/.n8n/config ]; then
    PERMS=$(stat -f "%Lp" ~/.n8n/config 2>/dev/null || stat -c "%a" ~/.n8n/config 2>/dev/null)
    if [ "$PERMS" != "600" ]; then
        echo -e "${YELLOW}  1. Corrigir permissões:${NC} ./scripts/fix_n8n_permissions.sh"
        ACTIONS_NEEDED=true
    fi
fi

# Verificar se precisa iniciar workers
if [ "$WORKER_COUNT" -eq 0 ] && [ -n "$MAIN_CONTAINER" ]; then
    echo -e "${YELLOW}  2. Iniciar workers:${NC} ./scripts/start_n8n_workers.sh 4"
    ACTIONS_NEEDED=true
fi

if [ "$ACTIONS_NEEDED" = false ]; then
    echo -e "${GREEN}  ✅ Nenhuma ação necessária - Sistema funcionando corretamente${NC}"
fi

echo ""
echo "✨ Manutenção concluída!"