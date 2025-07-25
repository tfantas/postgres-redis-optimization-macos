#!/bin/bash

echo "🚀 Aplicando otimizações ao PostgreSQL..."

# Backup da configuração atual
echo "📦 Fazendo backup da configuração atual..."
cp /usr/local/var/postgresql@15/postgresql.conf /usr/local/var/postgresql@15/postgresql.conf.backup.$(date +%Y%m%d_%H%M%S)

# Aplicar configurações otimizadas
echo "⚙️  Aplicando novas configurações..."

# Função para atualizar ou adicionar configuração
update_config() {
    local key=$1
    local value=$2
    local config_file="/usr/local/var/postgresql@15/postgresql.conf"
    
    if grep -q "^${key}" "$config_file"; then
        # Atualiza configuração existente
        sed -i '' "s/^${key}.*/${key} = ${value}/" "$config_file"
    else
        # Adiciona nova configuração
        echo "${key} = ${value}" >> "$config_file"
    fi
}

# Aplicar configurações de memória
update_config "shared_buffers" "16GB"
update_config "effective_cache_size" "48GB"
update_config "maintenance_work_mem" "2GB"
update_config "work_mem" "256MB"
update_config "wal_buffers" "512MB"

# Aplicar configurações de paralelismo
update_config "max_worker_processes" "16"
update_config "max_parallel_workers" "12"
update_config "max_parallel_workers_per_gather" "4"

# Aplicar configurações para SSD
update_config "random_page_cost" "1.1"
update_config "effective_io_concurrency" "200"

# Aplicar outras otimizações
update_config "default_statistics_target" "200"
update_config "autovacuum_max_workers" "4"
update_config "autovacuum_naptime" "10s"

# Logging útil para desenvolvimento
update_config "log_statement" "'mod'"
update_config "log_min_duration_statement" "1000"
update_config "log_line_prefix" "'%t [%p]: [%l-1] db=%d,user=%u,app=%a,client=%h '"

echo "✅ Configurações aplicadas!"

echo ""
echo "🔄 Para aplicar as mudanças, execute:"
echo "  brew services restart postgresql@15"
echo ""
echo "📊 Para verificar as novas configurações após reiniciar:"
echo "  /usr/local/opt/postgresql@15/bin/psql -U odin -d postgres -c 'SHOW shared_buffers;'"