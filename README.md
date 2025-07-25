# 🚀 PostgreSQL & Redis Optimization for macOS

Scripts e configurações profissionais para otimizar PostgreSQL e Redis em macOS com alta memória RAM (64GB+).

## 📊 Resultados das Otimizações

### Antes
- PostgreSQL: 128MB RAM (0.2% de 64GB)
- Redis: Sem limite de memória
- Performance: ~1K ops/seg

### Depois
- PostgreSQL: 16GB RAM (25% de 64GB)
- Redis: 12GB RAM com I/O threads
- Performance: >40K ops/seg

## 🎯 O que está incluído

### 1. Scripts de Otimização
- `scripts/apply_postgresql_optimization.sh` - Otimiza PostgreSQL para usar 25% da RAM
- `scripts/optimize_redis_full.sh` - Configura Redis com 12GB e I/O threads
- `scripts/migrate_*_to_native.sh` - Migra dados do Docker para serviços nativos
- `scripts/start_n8n_clean.sh` - Inicia n8n limpo com serviços nativos

### 2. Exemplo BullMQ com Dashboard Visual
Implementação completa de filas com Redis otimizado:
- 3 tipos de filas (email, imagem, analytics)
- Dashboard visual em tempo real (Chart.js + Tailwind)
- Gráficos de performance e métricas
- Teste de performance incluído

### 3. Integração n8n
- n8n configurado para usar PostgreSQL e Redis nativos
- Scripts prontos para produção
- 4+ workers paralelos
- Workflows de exemplo

### 4. Documentação Completa
- Configurações técnicas explicadas
- Comparação PostgreSQL vs Redis para filas
- Integração n8n + BullMQ
- Best practices e troubleshooting

## 🚀 Quick Start

### 1. Clonar o repositório
```bash
git clone https://github.com/tfantas/postgres-redis-optimization-macos.git
cd postgres-redis-optimization-macos
```

### 2. Aplicar otimizações

#### PostgreSQL
```bash
./scripts/apply_postgresql_optimization.sh
brew services restart postgresql@15
```

#### Redis
```bash
./scripts/optimize_redis_full.sh
```

### 3. Testar BullMQ
```bash
cd bullmq_example
npm install
npm run dashboard  # http://localhost:3001
npm run producer   # Adicionar jobs
npm run worker     # Processar jobs
```

### 4. Iniciar n8n
```bash
./scripts/start_n8n_clean.sh       # Inicia n8n limpo e otimizado
# Acesse: http://localhost:5678
```


## 📋 Pré-requisitos

- macOS com 16GB+ RAM (otimizado para 64GB)
- Homebrew
- PostgreSQL 15+ (`brew install postgresql@15`)
- Redis 7+ (`brew install redis`)
- Node.js 16+

## 🔧 Configurações Aplicadas

### PostgreSQL
```ini
shared_buffers = 16GB          # 25% da RAM
effective_cache_size = 48GB    # 75% da RAM
work_mem = 256MB
maintenance_work_mem = 2GB
max_parallel_workers = 12
```

### Redis
```ini
maxmemory 12gb
maxmemory-policy allkeys-lru
io-threads 8
io-threads-do-reads yes
appendonly yes
```

## 📂 Estrutura do Projeto

```
├── scripts/           # Scripts de otimização
├── configs/          # Arquivos de configuração
├── migrations/       # Scripts de migração
├── docs/            # Documentação detalhada
└── bullmq_example/  # Exemplo completo com BullMQ
```

## 🎯 Casos de Uso

1. **Desenvolvimento Local**: Aproveite toda a RAM do seu Mac
2. **Migração Docker → Nativo**: Scripts prontos para migrar
3. **Filas de Alta Performance**: BullMQ com Redis otimizado
4. **Análise de Performance**: Ferramentas de benchmark incluídas

## 📈 Performance

Com as otimizações aplicadas:

- **PostgreSQL**: Queries paralelas até 12x mais rápidas
- **Redis**: >40K operações/segundo
- **BullMQ**: >10K jobs/segundo

## 🤝 Contribuindo

1. Fork o projeto
2. Crie sua feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 🙏 Agradecimentos

- Comunidade PostgreSQL
- Comunidade Redis
- Equipe BullMQ

---

⭐ Se este projeto te ajudou, considere dar uma estrela!

🐛 Encontrou um bug? [Abra uma issue](https://github.com/tfantas/postgres-redis-optimization-macos/issues)