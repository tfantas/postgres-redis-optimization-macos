// Configuração dos gráficos
const chartConfig = {
    type: 'doughnut',
    options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: { display: false }
        }
    }
};

// Inicializar gráficos
const emailChart = new Chart(document.getElementById('emailChart'), {
    ...chartConfig,
    data: {
        labels: ['Aguardando', 'Processando', 'Completos', 'Falhas'],
        datasets: [{
            data: [0, 0, 0, 0],
            backgroundColor: ['#fbbf24', '#60a5fa', '#34d399', '#f87171']
        }]
    }
});

const imageChart = new Chart(document.getElementById('imageChart'), {
    ...chartConfig,
    data: {
        labels: ['Aguardando', 'Processando', 'Completos', 'Falhas'],
        datasets: [{
            data: [0, 0, 0, 0],
            backgroundColor: ['#fbbf24', '#60a5fa', '#34d399', '#f87171']
        }]
    }
});

const analyticsChart = new Chart(document.getElementById('analyticsChart'), {
    ...chartConfig,
    data: {
        labels: ['Aguardando', 'Processando', 'Completos', 'Falhas'],
        datasets: [{
            data: [0, 0, 0, 0],
            backgroundColor: ['#fbbf24', '#60a5fa', '#34d399', '#f87171']
        }]
    }
});

// Gráfico em tempo real
const realtimeChart = new Chart(document.getElementById('realtimeChart'), {
    type: 'line',
    data: {
        labels: [],
        datasets: [
            {
                label: 'Jobs/seg',
                data: [],
                borderColor: '#34d399',
                backgroundColor: 'rgba(52, 211, 153, 0.1)',
                tension: 0.4
            },
            {
                label: 'Latência (ms)',
                data: [],
                borderColor: '#fbbf24',
                backgroundColor: 'rgba(251, 191, 36, 0.1)',
                tension: 0.4
            }
        ]
    },
    options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
            y: { beginAtZero: true }
        },
        plugins: {
            legend: { position: 'top' }
        }
    }
});

// Variáveis de controle
let previousStats = null;
let jobsProcessedHistory = [];

// Função para atualizar estatísticas
async function updateStats() {
    try {
        const response = await fetch('/api/stats');
        const data = await response.json();
        
        // Atualizar contadores
        document.getElementById('email-waiting').textContent = data.email.waiting + data.email.prioritized;
        document.getElementById('email-active').textContent = data.email.active;
        document.getElementById('email-completed').textContent = data.email.completed;
        document.getElementById('email-failed').textContent = data.email.failed;
        
        document.getElementById('image-waiting').textContent = data.image.waiting;
        document.getElementById('image-active').textContent = data.image.active;
        document.getElementById('image-completed').textContent = data.image.completed;
        document.getElementById('image-failed').textContent = data.image.failed;
        
        document.getElementById('analytics-waiting').textContent = data.analytics.waiting;
        document.getElementById('analytics-active').textContent = data.analytics.active;
        document.getElementById('analytics-completed').textContent = data.analytics.completed;
        document.getElementById('analytics-failed').textContent = data.analytics.failed;
        
        // Atualizar gráficos de pizza
        emailChart.data.datasets[0].data = [
            data.email.waiting + data.email.prioritized,
            data.email.active,
            data.email.completed,
            data.email.failed
        ];
        emailChart.update();
        
        imageChart.data.datasets[0].data = [
            data.image.waiting,
            data.image.active,
            data.image.completed,
            data.image.failed
        ];
        imageChart.update();
        
        analyticsChart.data.datasets[0].data = [
            data.analytics.waiting,
            data.analytics.active,
            data.analytics.completed,
            data.analytics.failed
        ];
        analyticsChart.update();
        
        // Calcular jobs por segundo
        if (previousStats) {
            const totalCompleted = data.email.completed + data.image.completed + data.analytics.completed;
            const previousCompleted = previousStats.email.completed + previousStats.image.completed + previousStats.analytics.completed;
            const jobsPerSecond = (totalCompleted - previousCompleted) / 2; // Atualiza a cada 2 segundos
            
            document.getElementById('jobsPerSecond').textContent = Math.round(jobsPerSecond);
            document.getElementById('jobsPerSecondBar').style.width = Math.min(100, (jobsPerSecond / 100) * 100) + '%';
            
            // Adicionar ao gráfico em tempo real
            const now = new Date().toLocaleTimeString();
            realtimeChart.data.labels.push(now);
            realtimeChart.data.datasets[0].data.push(jobsPerSecond);
            
            // Simular latência
            const latency = Math.random() * 50 + 10;
            document.getElementById('latency').textContent = Math.round(latency) + 'ms';
            document.getElementById('latencyBar').style.width = Math.min(100, (latency / 100) * 100) + '%';
            realtimeChart.data.datasets[1].data.push(latency);
            
            // Manter apenas últimos 20 pontos
            if (realtimeChart.data.labels.length > 20) {
                realtimeChart.data.labels.shift();
                realtimeChart.data.datasets[0].data.shift();
                realtimeChart.data.datasets[1].data.shift();
            }
            
            realtimeChart.update();
        }
        
        previousStats = data;
        
        // Simular métricas do sistema
        const pgCpu = Math.random() * 30 + 10;
        document.getElementById('pgCpu').textContent = Math.round(pgCpu) + '%';
        document.getElementById('pgCpuBar').style.width = pgCpu + '%';
        
        const redisMemoryUsed = Math.random() * 2 + 0.5;
        document.getElementById('redisMemory').textContent = redisMemoryUsed.toFixed(1) + 'GB';
        document.getElementById('redisMemoryBar').style.width = (redisMemoryUsed / 12) * 100 + '%';
        
    } catch (error) {
        console.error('Erro ao buscar estatísticas:', error);
        document.getElementById('status').innerHTML = `
            <div class="w-3 h-3 bg-red-500 rounded-full mr-2"></div>
            <span class="text-sm">Erro de conexão</span>
        `;
    }
}

// Atualizar a cada 2 segundos
updateStats();
setInterval(updateStats, 2000);

// Adicionar animações suaves
document.addEventListener('DOMContentLoaded', () => {
    const elements = document.querySelectorAll('.glass-effect');
    elements.forEach((el, index) => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(20px)';
        setTimeout(() => {
            el.style.transition = 'all 0.5s ease-out';
            el.style.opacity = '1';
            el.style.transform = 'translateY(0)';
        }, index * 100);
    });
});