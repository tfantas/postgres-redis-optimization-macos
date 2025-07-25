# BullMQ com Redis Otimizado

Este exemplo demonstra o uso do BullMQ com Redis otimizado para máxima performance.

## 🚀 Configurações Aplicadas

### PostgreSQL (16GB RAM)
- **shared_buffers**: 16GB (era 128MB)
- **work_mem**: 256MB (era 4MB)
- **max_parallel_workers**: 12

### Redis (12GB RAM)
- **maxmemory**: 12GB
- **I/O threads**: 8
- **Persistência**: RDB + AOF
- **Lazy freeing**: Ativado

## 📦 Instalação

```bash
cd /Users/odin/Projetos/2025/bullmq_example
npm install
```

## 🎯 Uso

### 1. Adicionar Jobs
```bash
npm run producer
```
Adiciona:
- 100 emails com prioridades
- 50 jobs de processamento de imagem
- 200 eventos de analytics
- 1 job recorrente diário

### 2. Processar Jobs
```bash
npm run worker
```
Processa com:
- Email: 50 workers simultâneos
- Imagem: 5 workers (CPU intensivo)
- Analytics: 10 workers com batch

### 3. Dashboard
```bash
npm run dashboard
```
Acesse: http://localhost:3000

### 4. Teste de Performance
```bash
npm run test
```
Testa throughput com 10.000 jobs

## 📊 Performance Esperada

Com as otimizações:
- **Throughput**: >10.000 jobs/segundo
- **Latência**: <10ms por job
- **Concorrência**: 100+ workers

## 🔧 Características

### Filas
1. **Email Queue**
   - Alta concorrência (50)
   - Rate limiting (100/seg)
   - Retry com backoff exponencial

2. **Image Processing**
   - Baixa concorrência (5)
   - Progresso em tempo real
   - Jobs longos com stall detection

3. **Analytics**
   - Processamento em batch
   - Auto-cleanup
   - Alto throughput

### Features BullMQ
- ✅ Prioridades
- ✅ Delays
- ✅ Rate limiting
- ✅ Retries
- ✅ Progresso
- ✅ Jobs recorrentes
- ✅ Bulk operations
- ✅ Dashboard visual

## 🛠️ Monitoramento

### Redis
```bash
redis-cli INFO stats
redis-cli MONITOR
```

### PostgreSQL
```sql
SELECT * FROM pg_stat_activity;
SELECT * FROM pg_stat_database;
```

## 💡 Dicas

1. Use `addBulk()` para adicionar muitos jobs
2. Configure `removeOnComplete` para limpar jobs antigos
3. Use `updateProgress()` para jobs longos
4. Implemente graceful shutdown
5. Monitor memory usage com `redis-cli INFO memory`