const { Queue, Worker, QueueEvents } = require('bullmq');
const { redisOptions } = require('./connection');

async function testPerformance() {
  console.log('🧪 Testando performance do BullMQ com Redis otimizado\n');
  
  const testQueue = new Queue('performance-test', { connection: redisOptions });
  const queueEvents = new QueueEvents('performance-test', { connection: redisOptions });
  
  let processed = 0;
  let startTime;
  const totalJobs = 10000;
  
  // Worker com alta concorrência
  const worker = new Worker('performance-test', async (job) => {
    // Job simples e rápido
    return { id: job.id, timestamp: Date.now() };
  }, {
    connection: redisOptions,
    concurrency: 100, // Alta concorrência
    removeOnComplete: { count: 0 },
    removeOnFail: { count: 0 }
  });
  
  worker.on('completed', () => {
    processed++;
    if (processed === totalJobs) {
      const duration = Date.now() - startTime;
      const throughput = (totalJobs / duration) * 1000;
      
      console.log('\n📊 Resultados:');
      console.log(`✅ Jobs processados: ${totalJobs}`);
      console.log(`⏱️  Tempo total: ${duration}ms`);
      console.log(`🚀 Throughput: ${throughput.toFixed(2)} jobs/segundo`);
      console.log(`💾 Memória Redis: 12GB (configurado)`);
      console.log(`🔧 I/O Threads: 8`);
      
      // Limpar e sair
      worker.close();
      testQueue.obliterate({ force: true }).then(() => {
        process.exit(0);
      });
    }
  });
  
  console.log(`📝 Adicionando ${totalJobs} jobs...`);
  
  // Adicionar jobs em bulk para melhor performance
  const jobs = [];
  for (let i = 0; i < totalJobs; i++) {
    jobs.push({
      name: 'test-job',
      data: { index: i, timestamp: Date.now() }
    });
  }
  
  // Adicionar em chunks de 1000
  startTime = Date.now();
  for (let i = 0; i < totalJobs; i += 1000) {
    await testQueue.addBulk(jobs.slice(i, i + 1000));
    process.stdout.write(`\r${i + 1000} jobs adicionados...`);
  }
  
  console.log(`\n✅ Todos os jobs adicionados. Processando...\n`);
  
  // Mostrar progresso
  const progressInterval = setInterval(async () => {
    const counts = await testQueue.getJobCounts();
    process.stdout.write(`\r⏳ Processando: ${processed}/${totalJobs} | Ativo: ${counts.active} | Aguardando: ${counts.waiting}`);
  }, 100);
  
  // Limpar interval quando terminar
  worker.on('drained', () => {
    clearInterval(progressInterval);
  });
}

// Comparação com configuração anterior
console.log('📊 Comparação de Performance:\n');
console.log('Configuração ANTERIOR:');
console.log('- shared_buffers: 128MB (0.2% da RAM)');
console.log('- Redis sem limite de memória');
console.log('- Sem I/O threads');
console.log('- Performance estimada: ~1K jobs/seg\n');

console.log('Configuração ATUAL:');
console.log('- shared_buffers: 16GB (25% da RAM)');
console.log('- Redis: 12GB com LRU');
console.log('- 8 I/O threads');
console.log('- Performance esperada: >10K jobs/seg\n');

// Executar teste
testPerformance().catch(console.error);