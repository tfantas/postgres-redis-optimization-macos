const { Redis } = require('ioredis');

// Configuração otimizada para Redis local
const redisOptions = {
  host: 'localhost',
  port: 6379,
  maxRetriesPerRequest: null,
  enableReadyCheck: false,
  // Otimizações para performance
  enableOfflineQueue: false,
  connectTimeout: 10000,
  // Reconexão automática
  retryStrategy: (times) => {
    const delay = Math.min(times * 50, 2000);
    return delay;
  }
};

// Criar conexão Redis
function createRedisConnection() {
  const redis = new Redis(redisOptions);
  
  redis.on('connect', () => {
    console.log('✅ Conectado ao Redis');
  });
  
  redis.on('error', (err) => {
    console.error('❌ Erro Redis:', err);
  });
  
  return redis;
}

module.exports = { redisOptions, createRedisConnection };