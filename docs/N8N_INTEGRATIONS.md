# 🔌 n8n Integrations, Plugins & Extensions

## 🌐 Integração One Simple API

### Visão Geral
O n8n suporta integração completa com [One Simple API](https://n8n.io/integrations/one-simple-api/), permitindo acesso unificado a múltiplas APIs através de um único endpoint.

### Configuração

```javascript
// Adicionar ao n8n via API
{
  "name": "One Simple API Integration",
  "nodes": [
    {
      "parameters": {
        "authentication": "apiKey",
        "resource": "unified",
        "operation": "request"
      },
      "name": "One Simple API",
      "type": "n8n-nodes-base.oneSimpleApi",
      "position": [450, 300]
    }
  ]
}
```

### Recursos Disponíveis
- ✅ Acesso unificado a 50+ APIs
- ✅ Autenticação centralizada
- ✅ Rate limiting automático
- ✅ Logs unificados

## 🤖 AI Agent Template

### Template Incluído: Your First AI Agent

Este template demonstra como criar um agente AI completo no n8n com:

#### Componentes
1. **Chat Interface** - Interface web para interação
2. **Google Gemini** - Modelo de linguagem
3. **Memory Buffer** - Contexto de conversação
4. **Tools Integration** - Ferramentas externas

#### Ferramentas Disponíveis
- **Get Weather** - API Open-Meteo para clima
- **Get News** - RSS feeds de notícias globais
- **Gmail** (opcional) - Envio de emails
- **Google Calendar** (opcional) - Gestão de eventos

#### Como Usar
```bash
# 1. Importar template via API
curl -X POST http://localhost:5678/api/v1/workflows \
  -H "X-N8N-API-KEY: sua_api_key" \
  -H "Content-Type: application/json" \
  -d @ai_agent_template.json

# 2. Configurar credenciais do Google Gemini
# 3. Ativar workflow
# 4. Acessar chat público
```

## 🔧 Plugins Essenciais

### 1. n8n-nodes-discord
Integração completa com Discord para bots e automações.

```bash
# Instalar via npm no container
docker exec -it n8n-clean npm install n8n-nodes-discord
```

### 2. n8n-nodes-github
Operações avançadas do GitHub além do node padrão.

### 3. n8n-nodes-openai-advanced
Features avançadas da OpenAI incluindo GPT-4 Vision e DALL-E 3.

### 4. n8n-nodes-postgres-extended
Operações avançadas de PostgreSQL com suporte a stored procedures.

## 🔌 Model Context Protocol (MCP)

### Integração MCP no n8n

O n8n pode se integrar com servidores MCP para expandir capacidades:

```javascript
// Configuração MCP
{
  "name": "MCP Server Integration",
  "nodes": [
    {
      "parameters": {
        "protocol": "mcp",
        "server": "localhost:3333",
        "tools": ["file-operations", "code-analysis"],
        "authentication": "token"
      },
      "name": "MCP Tools",
      "type": "n8n-nodes-base.mcpServer"
    }
  ]
}
```

### Benefícios do MCP
- ✅ Acesso a ferramentas locais
- ✅ Operações de sistema seguras
- ✅ Integração com IDEs
- ✅ Context sharing entre aplicações

## 📦 Community Nodes

### Top 10 Nodes da Comunidade

1. **n8n-nodes-supabase** - Integração completa Supabase
2. **n8n-nodes-whatsapp** - WhatsApp Business API
3. **n8n-nodes-stripe-extended** - Stripe com webhooks
4. **n8n-nodes-aws-extended** - Serviços AWS adicionais
5. **n8n-nodes-google-workspace** - Suite completa Google
6. **n8n-nodes-microsoft-teams** - Teams integration
7. **n8n-nodes-shopify-plus** - Shopify avançado
8. **n8n-nodes-twilio-extended** - SMS/Voice completo
9. **n8n-nodes-airtable-enhanced** - Airtable com views
10. **n8n-nodes-notion-extended** - Notion databases

### Instalação de Community Nodes

```bash
# Via UI
Settings → Community Nodes → Install

# Via Docker
docker exec -it n8n-clean npm install [node-package]

# Via Environment
N8N_COMMUNITY_PACKAGES_ENABLED=true
```

## 🔮 Integrações AI/ML

### LangChain Integration
```javascript
{
  "nodes": [
    {
      "type": "@n8n/n8n-nodes-langchain.agent",
      "parameters": {
        "model": "gpt-4",
        "tools": ["calculator", "web-search", "code-interpreter"],
        "memory": "conversation-buffer"
      }
    }
  ]
}
```

### Vector Databases
- **Pinecone** - Busca semântica
- **Weaviate** - Knowledge graphs
- **Qdrant** - High-performance vectors
- **ChromaDB** - Local embeddings

## 🚀 Workflows Prontos

### 1. Customer Support Bot
```json
{
  "name": "AI Customer Support",
  "description": "Chatbot com FAQ, ticket creation e escalation",
  "integrations": ["Slack", "Zendesk", "OpenAI", "PostgreSQL"]
}
```

### 2. Data Pipeline ETL
```json
{
  "name": "ETL Pipeline",
  "description": "Extract, transform, load com validação",
  "integrations": ["PostgreSQL", "Redis", "S3", "Webhook"]
}
```

### 3. Social Media Automation
```json
{
  "name": "Social Publisher",
  "description": "Post scheduling multi-platform",
  "integrations": ["Twitter", "LinkedIn", "Instagram", "Buffer"]
}
```

## 📊 Monitoring & Analytics

### Prometheus Exporter
```yaml
# Adicionar ao docker-compose
n8n_exporter:
  image: n8n-prometheus-exporter
  environment:
    - N8N_URL=http://n8n:5678
    - METRICS_PORT=9090
```

### Grafana Dashboards
- Workflow execution metrics
- Error rates and patterns
- Resource utilization
- API usage statistics

## 🔐 Security Plugins

### 1. OAuth2 Proxy
Adiciona camada extra de autenticação.

### 2. Vault Integration
Gestão segura de credenciais.

### 3. SIEM Connector
Envio de logs para sistemas SIEM.

## 📱 Mobile & Desktop

### n8n Companion Apps
- **iOS/Android** - Monitor workflows
- **Desktop** - Electron app
- **CLI** - Command line interface
- **VS Code Extension** - Development

## 🎯 Best Practices

### 1. Organização de Nodes
```
- Use sticky notes para documentação
- Agrupe nodes relacionados
- Nomeie nodes descritivamente
- Use cores para categorizar
```

### 2. Error Handling
```javascript
// Sempre adicione error workflows
{
  "errorWorkflow": "error-handler-workflow-id",
  "continueOnFail": true,
  "retryOnFail": true,
  "maxRetries": 3
}
```

### 3. Performance
```
- Limite nodes por workflow (<50)
- Use sub-workflows para modularizar
- Implemente caching com Redis
- Monitor execução com métricas
```

## 🔄 Próximas Integrações

### Roadmap 2025
1. **Native MCP Support** - Q1 2025
2. **GraphQL Nodes** - Q2 2025
3. **Kubernetes Operator** - Q2 2025
4. **Edge Computing** - Q3 2025
5. **WebAssembly Nodes** - Q4 2025

## 📚 Recursos Adicionais

- [n8n Integrations Hub](https://n8n.io/integrations/)
- [Community Forum](https://community.n8n.io/)
- [Node Development Guide](https://docs.n8n.io/integrations/creating-nodes/)
- [API Documentation](https://docs.n8n.io/api/)

---

Esta documentação será atualizada conforme novas integrações forem adicionadas ao sistema.