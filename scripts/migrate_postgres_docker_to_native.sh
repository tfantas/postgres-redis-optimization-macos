#!/bin/bash

echo "🔄 Migrando dados do PostgreSQL Docker para PostgreSQL nativo"
echo ""

# Criar diretório para backup
BACKUP_DIR="/tmp/postgres_migration_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "📦 Listando bancos de dados no PostgreSQL Docker..."

# Listar bancos no Docker (exceto templates)
DATABASES=$(docker exec aix-postgres psql -U postgres -t -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datname != 'postgres';" | grep -v '^$' | sed 's/^[ \t]*//;s/[ \t]*$//')

echo "Bancos encontrados:"
echo "$DATABASES"
echo "---"

# Fazer backup de cada banco
for DB in $DATABASES; do
    echo "📦 Fazendo backup do banco: $DB"
    docker exec aix-postgres pg_dump -U postgres -d "$DB" > "$BACKUP_DIR/${DB}.sql"
    
    if [ -f "$BACKUP_DIR/${DB}.sql" ] && [ -s "$BACKUP_DIR/${DB}.sql" ]; then
        echo "✅ Backup criado: $BACKUP_DIR/${DB}.sql ($(ls -lh "$BACKUP_DIR/${DB}.sql" | awk '{print $5}'))"
        
        # Criar banco no PostgreSQL nativo se não existir
        echo "🗄️  Criando banco '$DB' no PostgreSQL nativo..."
        /usr/local/opt/postgresql@15/bin/createdb -U odin "$DB" 2>/dev/null || echo "   Banco já existe"
        
        # Importar dados
        echo "📥 Importando dados para o banco '$DB'..."
        /usr/local/opt/postgresql@15/bin/psql -U odin -d "$DB" < "$BACKUP_DIR/${DB}.sql"
        
        if [ $? -eq 0 ]; then
            echo "✅ Banco '$DB' migrado com sucesso!"
        else
            echo "⚠️  Aviso: Alguns erros podem ter ocorrido durante a importação de '$DB'"
        fi
        echo ""
    else
        echo "⚠️  Aviso: Backup vazio ou falhou para o banco '$DB'"
    fi
done

# Fazer backup também do banco postgres (dados do sistema)
echo "📦 Fazendo backup do banco 'postgres' (dados globais)..."
docker exec aix-postgres pg_dumpall -U postgres --globals-only > "$BACKUP_DIR/globals.sql"

# Importar roles e permissões (se houver)
if [ -f "$BACKUP_DIR/globals.sql" ] && [ -s "$BACKUP_DIR/globals.sql" ]; then
    echo "📥 Importando roles e permissões globais..."
    /usr/local/opt/postgresql@15/bin/psql -U odin -d postgres < "$BACKUP_DIR/globals.sql" 2>/dev/null
fi

echo ""
echo "📊 Resumo da migração:"
echo "---"
echo "Backups salvos em: $BACKUP_DIR"
echo ""

# Listar bancos no PostgreSQL nativo
echo "Bancos no PostgreSQL nativo:"
/usr/local/opt/postgresql@15/bin/psql -U odin -d postgres -c "\l"

# Parar container Docker
echo ""
read -p "🛑 Deseja parar o container PostgreSQL Docker? (s/n): " resposta
if [[ "$resposta" =~ ^[Ss]$ ]]; then
    docker stop aix-postgres
    echo "✅ Container PostgreSQL Docker parado"
fi

echo ""
echo "✅ Migração concluída!"
echo "   PostgreSQL nativo: localhost:5432"
echo "   Usuário: odin"
echo ""
echo "💡 Para verificar os dados migrados:"
echo "   psql -U odin -d nome_do_banco"