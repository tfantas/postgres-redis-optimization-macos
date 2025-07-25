const { Worker, QueueEvents } = require('bullmq');
const { redisOptions } = require('./connection');

// Simulação de processamento
const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// Email Worker - Alta concorrência
const emailWorker = new Worker('email', async (job) => {
  console.log(`📧 Processando email ${job.id} para ${job.data.to}`);
  
  // Simular envio de email
  await sleep(Math.random() * 100);
  
  // Simular falha ocasional
  if (Math.random() < 0.1) {
    throw new Error('Falha no servidor SMTP');
  }
  
  return { sent: true, timestamp: Date.now() };
}, {
  connection: redisOptions,
  concurrency: 50, // Processar 50 emails simultaneamente
  limiter: {
    max: 100,
    duration: 1000 // Max 100 emails por segundo
  }
});

// Image Worker - CPU intensivo
const imageWorker = new Worker('image-processing', async (job) => {
  console.log(`🖼️  Processando imagem ${job.data.imageUrl}`);
  const updateProgress = (progress) => job.updateProgress(progress);
  
  // Simular processamento com progresso
  updateProgress(10);
  await sleep(500);
  
  updateProgress(50);
  await sleep(1000);
  
  updateProgress(90);
  await sleep(500);
  
  updateProgress(100);
  
  return {
    processed: true,
    sizes: job.data.sizes,
    duration: 2000
  };
}, {
  connection: redisOptions,
  concurrency: 5, // Limitar concorrência para jobs pesados
  // Configurações para jobs longos
  stallInterval: 30000,
  maxStalledCount: 2
});

// Analytics Worker - Alto throughput
const analyticsWorker = new Worker('analytics', async (job) => {
  const batch = [];
  
  // Processar em batch para eficiência
  batch.push(job.data);
  
  // Pegar mais jobs do mesmo tipo
  let nextJob;
  for (let i = 0; i < 9; i++) {
    nextJob = await job.queue.getNextJob();
    if (nextJob) {
      batch.push(nextJob.data);
    }
  }
  
  console.log(`📊 Processando batch de ${batch.length} eventos`);
  
  // Simular gravação em banco
  await sleep(50);
  
  return { 
    batchSize: batch.length,
    processed: true 
  };
}, {
  connection: redisOptions,
  concurrency: 10,
  // Auto-remover jobs completos
  removeOnComplete: { count: 0 },
  removeOnFail: { count: 1000 }
});

// Event listeners
emailWorker.on('completed', (job) => {
  console.log(`✅ Email ${job.id} enviado com sucesso`);
});

emailWorker.on('failed', (job, err) => {
  console.log(`❌ Email ${job.id} falhou: ${err.message}`);
});

imageWorker.on('progress', (job, progress) => {
  console.log(`🔄 Imagem ${job.id}: ${progress}% completo`);
});

// Queue Events (monitoramento global)
const emailQueueEvents = new QueueEvents('email', { connection: redisOptions });

emailQueueEvents.on('waiting', ({ jobId }) => {
  console.log(`⏳ Job ${jobId} aguardando processamento`);
});

emailQueueEvents.on('stalled', ({ jobId }) => {
  console.log(`⚠️  Job ${jobId} travado - será reprocessado`);
});

// Estatísticas a cada 5 segundos
setInterval(async () => {
  console.log('\n📈 Estatísticas dos Workers:');
  console.log(`Email Worker: ${emailWorker.isRunning() ? 'Rodando' : 'Parado'}`);
  console.log(`Image Worker: ${imageWorker.isRunning() ? 'Rodando' : 'Parado'}`);
  console.log(`Analytics Worker: ${analyticsWorker.isRunning() ? 'Rodando' : 'Parado'}`);
}, 5000);

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('🛑 Parando workers...');
  await emailWorker.close();
  await imageWorker.close();
  await analyticsWorker.close();
  process.exit(0);
});

console.log('🚀 Workers iniciados!');
console.log('Concorrência: Email(50), Imagem(5), Analytics(10)');