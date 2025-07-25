const express = require('express');
const path = require('path');
const { createBullBoard } = require('@bull-board/api');
const { BullMQAdapter } = require('@bull-board/api/bullMQAdapter');
const { ExpressAdapter } = require('@bull-board/express');
const { Queue } = require('bullmq');
const { redisOptions } = require('./connection');

// Criar app Express
const app = express();

// Servir arquivos estáticos
app.use(express.static(path.join(__dirname, 'public')));

// Criar adaptador para Express
const serverAdapter = new ExpressAdapter();
serverAdapter.setBasePath('/admin/queues');

// Criar queues
const emailQueue = new Queue('email', { connection: redisOptions });
const imageQueue = new Queue('image-processing', { connection: redisOptions });
const analyticsQueue = new Queue('analytics', { connection: redisOptions });

// Criar Bull Board
createBullBoard({
  queues: [
    new BullMQAdapter(emailQueue),
    new BullMQAdapter(imageQueue),
    new BullMQAdapter(analyticsQueue)
  ],
  serverAdapter: serverAdapter,
  options: {
    uiConfig: {
      boardTitle: 'BullMQ Dashboard',
      boardLogo: {
        path: 'https://raw.githubusercontent.com/felixmosh/bull-board/master/packages/ui/src/static/images/logo.svg',
        width: '100px',
        height: 35
      }
    }
  }
});

// Adicionar rota do Bull Board
app.use('/admin/queues', serverAdapter.getRouter());

// Servir o dashboard visual na raiz
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Rota de estatísticas em texto (antiga home)
app.get('/stats-text', async (req, res) => {
  const emailStats = await emailQueue.getJobCounts();
  const imageStats = await imageQueue.getJobCounts();
  const analyticsStats = await analyticsQueue.getJobCounts();
  
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>BullMQ Dashboard</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .stats { background: #f0f0f0; padding: 20px; border-radius: 8px; margin: 20px 0; }
        .queue { margin: 10px 0; }
        a { color: #0066cc; text-decoration: none; }
        a:hover { text-decoration: underline; }
      </style>
    </head>
    <body>
      <h1>🚀 BullMQ com Redis Otimizado</h1>
      
      <div class="stats">
        <h2>📊 Estatísticas das Filas</h2>
        
        <div class="queue">
          <h3>📧 Email Queue</h3>
          <ul>
            <li>Aguardando: ${emailStats.waiting}</li>
            <li>Ativo: ${emailStats.active}</li>
            <li>Completo: ${emailStats.completed}</li>
            <li>Falhou: ${emailStats.failed}</li>
            <li>Atrasado: ${emailStats.delayed}</li>
          </ul>
        </div>
        
        <div class="queue">
          <h3>🖼️ Image Processing Queue</h3>
          <ul>
            <li>Aguardando: ${imageStats.waiting}</li>
            <li>Ativo: ${imageStats.active}</li>
            <li>Completo: ${imageStats.completed}</li>
            <li>Falhou: ${imageStats.failed}</li>
            <li>Atrasado: ${imageStats.delayed}</li>
          </ul>
        </div>
        
        <div class="queue">
          <h3>📊 Analytics Queue</h3>
          <ul>
            <li>Aguardando: ${analyticsStats.waiting}</li>
            <li>Ativo: ${analyticsStats.active}</li>
            <li>Completo: ${analyticsStats.completed}</li>
            <li>Falhou: ${analyticsStats.failed}</li>
            <li>Atrasado: ${analyticsStats.delayed}</li>
          </ul>
        </div>
      </div>
      
      <p>
        <a href="/admin/queues">📈 Abrir Dashboard Completo</a>
      </p>
      
      <h2>🛠️ Comandos Úteis</h2>
      <pre>
npm run producer  # Adicionar jobs
npm run worker    # Processar jobs
npm run test      # Testar performance
      </pre>
    </body>
    </html>
  `);
});

// API endpoints
app.get('/api/stats', async (req, res) => {
  const stats = {
    email: await emailQueue.getJobCounts(),
    image: await imageQueue.getJobCounts(),
    analytics: await analyticsQueue.getJobCounts(),
    redis: {
      maxMemory: '12GB',
      ioThreads: 8,
      persistence: 'RDB + AOF'
    }
  };
  res.json(stats);
});

// Iniciar servidor
const PORT = 3001;
app.listen(PORT, () => {
  console.log(`🚀 Dashboard rodando em http://localhost:${PORT}`);
  console.log(`📊 Bull Board em http://localhost:${PORT}/admin/queues`);
});