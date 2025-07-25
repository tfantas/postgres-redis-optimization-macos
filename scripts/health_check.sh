#!/bin/bash

echo "🏥 Verificação de Saúde do Sistema"
echo "=================================="
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Contadores
TOTAL_CHECKS=0
PASSED_CHECKS=0
WARNINGS=0
ERRORS=0

# Função para verificar status
check_status() {
    local name=$1
    local command=$2
    local expected=$3
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    echo -n "Verificando $name... "
    
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        if [ "$expected" = "warning" ]; then
            echo -e "${YELLOW}⚠️  Warning${NC}"
            WARNINGS=$((WARNINGS + 1))
            return 1
        else
            echo -e "${RED}❌ Erro${NC}"
            ERRORS=$((ERRORS + 1))
            return 2
        fi
    fi
}

echo "🔍 1. Serviços Nativos"
echo "---------------------"

# PostgreSQL
check_status "PostgreSQL" "brew services list | grep 'postgresql@15.*started' > /dev/null"
check_status "PostgreSQL conexão" "/usr/local/opt/postgresql@15/bin/psql -U odin -d postgres -c 'SELECT 1' > /dev/null 2>&1"
check_status "Banco n8n_eternal" "/usr/local/opt/postgresql@15/bin/psql -U odin -d n8n_eternal -c 'SELECT 1' > /dev/null 2>&1"

# Redis
check_status "Redis" "brew services list | grep 'redis.*started' > /dev/null"
check_status "Redis conexão" "redis-cli ping > /dev/null 2>&1"
check_status "Redis DB 0 (BullMQ)" "redis-cli -n 0 ping > /dev/null 2>&1"
check_status "Redis DB 1 (n8n)" "redis-cli -n 1 ping > /dev/null 2>&1"

echo ""
echo "🐳 2. Containers Docker"
echo "----------------------"

# n8n
check_status "n8n principal" "docker ps | grep -E '(n8n-native|n8n-clean)' | grep -v 'worker' > /dev/null"
check_status "n8n workers (4)" "[ $(docker ps | grep 'n8n-worker' | wc -l) -eq 4 ]"
check_status "n8n Web UI" "curl -s http://localhost:5678 > /dev/null 2>&1"

echo ""
echo "💾 3. Recursos do Sistema"
echo "------------------------"

# Memória PostgreSQL
PG_MEM=$(/usr/local/opt/postgresql@15/bin/psql -U odin -d postgres -t -c "SHOW shared_buffers" 2>/dev/null | tr -d ' ')
echo -e "PostgreSQL shared_buffers: ${BLUE}$PG_MEM${NC}"
if [[ "$PG_MEM" == "16GB" ]]; then
    echo -e "  ${GREEN}✅ Otimizado${NC}"
else
    echo -e "  ${YELLOW}⚠️  Não otimizado (esperado: 16GB)${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# Memória Redis
REDIS_MEM=$(redis-cli CONFIG GET maxmemory | tail -1)
REDIS_MEM_GB=$((REDIS_MEM / 1024 / 1024 / 1024))
echo -e "Redis maxmemory: ${BLUE}${REDIS_MEM_GB}GB${NC}"
if [ "$REDIS_MEM_GB" -ge 10 ]; then
    echo -e "  ${GREEN}✅ Otimizado${NC}"
else
    echo -e "  ${YELLOW}⚠️  Não otimizado (esperado: 12GB)${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

echo ""
echo "🌐 4. Endpoints e Dashboards"
echo "---------------------------"

check_status "Dashboard BullMQ (3001)" "curl -s http://localhost:3001 > /dev/null 2>&1"
check_status "Bull Board (3001/admin/queues)" "curl -s http://localhost:3001/admin/queues > /dev/null 2>&1"
check_status "n8n (5678)" "curl -s http://localhost:5678 > /dev/null 2>&1"

echo ""
echo "📊 5. Estatísticas Operacionais"
echo "-------------------------------"

# Jobs no BullMQ
if redis-cli ping > /dev/null 2>&1; then
    BULL_WAITING=$(redis-cli -n 0 LLEN bull:email:wait 2>/dev/null || echo "0")
    BULL_ACTIVE=$(redis-cli -n 0 LLEN bull:email:active 2>/dev/null || echo "0")
    echo "BullMQ Email Queue:"
    echo "  Aguardando: $BULL_WAITING"
    echo "  Processando: $BULL_ACTIVE"
fi

# Workflows ativos no n8n
if /usr/local/opt/postgresql@15/bin/psql -U odin -d n8n_eternal -c "SELECT 1" > /dev/null 2>&1; then
    ACTIVE_WF=$(/usr/local/opt/postgresql@15/bin/psql -U odin -d n8n_eternal -t -c "SELECT COUNT(*) FROM workflow_entity WHERE active = true" 2>/dev/null | tr -d ' ')
    echo "n8n Workflows ativos: $ACTIVE_WF"
fi

echo ""
echo "🔒 6. Segurança"
echo "---------------"

# Permissões n8n
if [ -f ~/.n8n/config ]; then
    PERMS=$(stat -f "%Lp" ~/.n8n/config 2>/dev/null || stat -c "%a" ~/.n8n/config 2>/dev/null)
    if [ "$PERMS" = "600" ]; then
        echo -e "Permissões ~/.n8n/config: ${GREEN}✅ 600${NC}"
    else
        echo -e "Permissões ~/.n8n/config: ${YELLOW}⚠️  $PERMS (recomendado: 600)${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

echo ""
echo "📋 Resumo"
echo "---------"
echo -e "Total de verificações: ${BLUE}$TOTAL_CHECKS${NC}"
echo -e "Passou: ${GREEN}$PASSED_CHECKS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo -e "Erros: ${RED}$ERRORS${NC}"

echo ""
if [ $ERRORS -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}✅ Sistema 100% saudável!${NC}"
    else
        echo -e "${YELLOW}⚠️  Sistema operacional com $WARNINGS avisos${NC}"
        echo ""
        echo "Ações recomendadas:"
        if [ "$PG_MEM" != "16GB" ]; then
            echo "  - Execute: ./scripts/apply_postgresql_optimization.sh"
        fi
        if [ "$REDIS_MEM_GB" -lt 10 ]; then
            echo "  - Execute: ./scripts/optimize_redis_full.sh"
        fi
        if [ "$PERMS" != "600" ] 2>/dev/null; then
            echo "  - Execute: ./scripts/fix_n8n_permissions.sh"
        fi
    fi
else
    echo -e "${RED}❌ Sistema com $ERRORS erros críticos${NC}"
    echo ""
    echo "Verifique os componentes com erro acima."
fi

echo ""
echo "✨ Verificação concluída em $(date '+%Y-%m-%d %H:%M:%S')"