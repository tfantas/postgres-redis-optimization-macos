#!/bin/bash

echo "🔄 Migrando dados do Redis Docker para Redis nativo"
echo ""

# Criar diretório para backup
BACKUP_DIR="/tmp/redis_migration_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "📦 Fazendo backup do Redis Docker (porta 6379)..."

# Fazer dump do Redis no Docker
docker exec aix-redis redis-cli BGSAVE
sleep 2

# Copiar arquivo dump.rdb do container
docker cp aix-redis:/data/dump.rdb "$BACKUP_DIR/dump.rdb"

if [ -f "$BACKUP_DIR/dump.rdb" ]; then
    echo "✅ Backup criado: $BACKUP_DIR/dump.rdb"
    
    # Parar Redis nativo temporariamente
    echo "🛑 Parando Redis nativo..."
    brew services stop redis
    sleep 2
    
    # Fazer backup do Redis nativo atual (se existir)
    if [ -f /usr/local/var/db/redis/dump.rdb ]; then
        cp /usr/local/var/db/redis/dump.rdb "$BACKUP_DIR/dump.rdb.native.backup"
        echo "📦 Backup do Redis nativo salvo em: $BACKUP_DIR/dump.rdb.native.backup"
    fi
    
    # Copiar dump do Docker para Redis nativo
    echo "📥 Importando dados para Redis nativo..."
    cp "$BACKUP_DIR/dump.rdb" /usr/local/var/db/redis/dump.rdb
    
    # Ajustar permissões
    chown $(whoami) /usr/local/var/db/redis/dump.rdb
    
    # Iniciar Redis nativo
    echo "🚀 Iniciando Redis nativo..."
    brew services start redis
    sleep 3
    
    # Verificar se Redis está rodando
    if redis-cli ping > /dev/null 2>&1; then
        echo "✅ Redis nativo iniciado com sucesso!"
        
        # Mostrar estatísticas
        echo ""
        echo "📊 Estatísticas da migração:"
        echo "Tamanho do backup: $(ls -lh $BACKUP_DIR/dump.rdb | awk '{print $5}')"
        echo "Número de chaves: $(redis-cli DBSIZE | awk '{print $2}')"
        
        # Parar container Docker
        echo ""
        echo "🛑 Parando container Redis Docker..."
        docker stop aix-redis
        
        echo ""
        echo "✅ Migração concluída com sucesso!"
        echo "   Redis nativo: localhost:6379"
        echo "   Backup salvo em: $BACKUP_DIR"
        
    else
        echo "❌ Erro ao iniciar Redis nativo"
        echo "Restaurando backup original..."
        if [ -f "$BACKUP_DIR/dump.rdb.native.backup" ]; then
            cp "$BACKUP_DIR/dump.rdb.native.backup" /usr/local/var/db/redis/dump.rdb
        fi
        brew services start redis
    fi
else
    echo "❌ Erro ao criar backup do Redis Docker"
fi

echo ""
echo "💡 Para verificar os dados migrados:"
echo "   redis-cli"
echo "   > KEYS *"