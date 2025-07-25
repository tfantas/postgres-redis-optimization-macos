const { Queue } = require('bullmq');
const { redisOptions } = require('./connection');

// Criar filas
const emailQueue = new Queue('email', { connection: redisOptions });
const imageQueue = new Queue('image-processing', { connection: redisOptions });
const analyticsQueue = new Queue('analytics', { connection: redisOptions });

async function addJobs() {
  console.log('🚀 Adicionando jobs às filas...\n');
  
  // Email jobs com prioridade
  const emailJobs = [];
  for (let i = 0; i < 100; i++) {
    emailJobs.push({
      name: `send-email-${i}`,
      data: {
        to: `user${i}@example.com`,
        subject: 'Bem-vindo!',
        template: 'welcome',
        priority: i < 10 ? 1 : 10 // Primeiros 10 com alta prioridade
      },
      opts: {
        priority: i < 10 ? 1 : 10,
        attempts: 3,
        backoff: {
          type: 'exponential',
          delay: 2000
        }
      }
    });
  }
  
  // Bulk add para performance
  await emailQueue.addBulk(emailJobs);
  console.log('✅ 100 emails adicionados');
  
  // Jobs de processamento de imagem com delay
  for (let i = 0; i < 50; i++) {
    await imageQueue.add('resize-image', {
      imageUrl: `https://example.com/image${i}.jpg`,
      sizes: ['thumbnail', 'medium', 'large']
    }, {
      delay: i * 1000, // Delay progressivo
      removeOnComplete: {
        age: 3600, // Manter por 1 hora
        count: 100 // Manter últimos 100
      },
      removeOnFail: {
        age: 24 * 3600 // Manter falhas por 24 horas
      }
    });
  }
  console.log('✅ 50 jobs de imagem adicionados com delay');
  
  // Jobs de analytics com rate limiting
  for (let i = 0; i < 200; i++) {
    await analyticsQueue.add('track-event', {
      userId: Math.floor(Math.random() * 1000),
      event: ['page_view', 'click', 'signup'][Math.floor(Math.random() * 3)],
      timestamp: Date.now()
    }, {
      // Rate limiting via job options
      delay: Math.floor(i / 10) * 100 // 10 jobs por 100ms
    });
  }
  console.log('✅ 200 eventos de analytics adicionados');
  
  // Job recorrente (cron-like)
  await emailQueue.add('daily-digest', 
    { type: 'digest' }, 
    {
      repeat: {
        pattern: '0 9 * * *', // Todo dia às 9h
        limit: 30 // Máximo 30 repetições
      }
    }
  );
  console.log('✅ Job recorrente configurado');
  
  // Estatísticas
  console.log('\n📊 Estatísticas das filas:');
  console.log(`Email: ${await emailQueue.getJobCounts()}`);
  console.log(`Imagem: ${await imageQueue.getJobCounts()}`);
  console.log(`Analytics: ${await analyticsQueue.getJobCounts()}`);
}

// Executar
addJobs()
  .then(() => {
    console.log('\n✨ Todos os jobs foram adicionados!');
    console.log('Execute "npm run worker" para processá-los');
    process.exit(0);
  })
  .catch(err => {
    console.error('Erro:', err);
    process.exit(1);
  });