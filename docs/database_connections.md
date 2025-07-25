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
