#!/bin/bash

echo "🔄 Atualizando configurações para usar serviços nativos..."
echo ""

# Função para criar arquivo de configuração padrão para conexões locais
create_local_config() {
    local project_path=$1
    local config_file="${project_path}/.env.local"
    
    echo "📝 Criando configuração local para: $project_path"
    
    cat > "$config_file" << 'EOF'
# Configurações para serviços nativos locais
# Gerado em: $(date)

# PostgreSQL Nativo
DB_HOST=localhost
DB_PORT=5432
DB_USER=odin
DB_PASSWORD=
DB_NAME=postgres

# URLs de conexão PostgreSQL
DATABASE_URL=postgresql://odin@localhost:5432/postgres
POSTGRES_URL=postgresql://odin@localhost:5432/postgres

# Redis Nativo
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_URL=redis://localhost:6379

# Bancos específicos disponíveis:
# - aix_memory: postgresql://odin@localhost:5432/aix_memory
# - claude_memory: postgresql://claude@localhost:5432/claude_memory
# - n8n_eternal: postgresql://odin@localhost:5432/n8n_eternal
EOF
    
    echo "✅ Criado: $config_file"
}

# Projetos identificados que podem precisar de atualização
PROJECTS=(
    "/Users/odin/Projetos/2025/Pessoais/claude-context-guardian-enterprise"
    "/Users/odin/Projetos/2025/Pessoais/claude-context-guardian-enterprise-new"
)

# Criar configurações locais para cada projeto
for project in "${PROJECTS[@]}"; do
    if [ -d "$project" ]; then
        create_local_config "$project"
    fi
done

# Criar arquivo de referência geral
echo ""
echo "📄 Criando arquivo de referência de conexões..."

cat > /Users/odin/Projetos/2025/database_connections.md << 'EOF'
# Conexões de Banco de Dados - Serviços Nativos

## PostgreSQL (localhost:5432)

### Conexão principal
```
Host: localhost
Port: 5432
User: odin
Password: (vazio)
URL: postgresql://odin@localhost:5432/postgres
```

### Bancos disponíveis:

#### aix_memory
```
Database: aix_memory
URL: postgresql://odin@localhost:5432/aix_memory
```

#### claude_memory
```
Database: claude_memory
User: claude
URL: postgresql://claude@localhost:5432/claude_memory
```

#### n8n_eternal
```
Database: n8n_eternal
URL: postgresql://odin@localhost:5432/n8n_eternal
```

## Redis (localhost:6379)

```
Host: localhost
Port: 6379
Password: (vazio)
URL: redis://localhost:6379
```

## Exemplos de uso em diferentes linguagens:

### Node.js / TypeScript
```javascript
// PostgreSQL
const DATABASE_URL = 'postgresql://odin@localhost:5432/postgres'

// Redis
const REDIS_URL = 'redis://localhost:6379'
```

### Python
```python
# PostgreSQL
DATABASE_URL = 'postgresql://odin@localhost:5432/postgres'

# Redis
REDIS_URL = 'redis://localhost:6379'
```

### Docker Compose (se precisar)
```yaml
services:
  app:
    environment:
      - DATABASE_URL=postgresql://odin@host.docker.internal:5432/postgres
      - REDIS_URL=redis://host.docker.internal:6379
```

## Notas:
- Todos os serviços estão rodando nativamente no macOS
- Não há senhas configuradas (autenticação local)
- Use `host.docker.internal` se conectar de dentro de containers
EOF

echo "✅ Arquivo de referência criado: /Users/odin/Projetos/2025/database_connections.md"

# Verificar se há aplicações n8n que precisam ser atualizadas
echo ""
echo "🔍 Verificando configurações do n8n..."

N8N_CONFIG_PATHS=(
    "$HOME/.n8n"
    "/Users/odin/Projetos/2025/n8n"
)

for path in "${N8N_CONFIG_PATHS[@]}"; do
    if [ -d "$path" ]; then
        echo "📁 Encontrado diretório n8n: $path"
        
        # Criar arquivo de configuração do n8n
        cat > "$path/config.json" << EOF
{
  "database": {
    "type": "postgresdb",
    "postgresdb": {
      "host": "localhost",
      "port": 5432,
      "database": "n8n_eternal",
      "user": "odin",
      "password": ""
    }
  },
  "executions": {
    "pruneData": true,
    "pruneDataMaxAge": 336
  }
}
EOF
        echo "✅ Configuração n8n atualizada"
    fi
done

echo ""
echo "✨ Configurações atualizadas para usar serviços nativos!"
echo ""
echo "📋 Resumo das mudanças:"
echo "   - PostgreSQL: Docker (5432) → Nativo (5432)"
echo "   - Redis: Docker (6379) → Nativo (6379)"
echo "   - Arquivos .env.local criados nos projetos"
echo "   - Arquivo de referência criado"
echo ""
echo "💡 Dica: Use os arquivos .env.local criados em seus projetos"