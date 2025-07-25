#!/bin/bash

echo "🔓 Configurando Proxy Reverso para n8n sem Autenticação"
echo ""

# Verificar se nginx está instalado
if ! command -v nginx &> /dev/null; then
    echo "📦 Nginx não encontrado. Instalando..."
    brew install nginx
fi

# Criar configuração do nginx
echo "⚙️  Criando configuração do proxy..."

# Criar diretório se não existir
mkdir -p /usr/local/etc/nginx/servers/

# Criar arquivo de configuração
cat > /usr/local/etc/nginx/servers/n8n-proxy.conf << 'EOF'
# Proxy reverso para n8n sem autenticação
server {
    listen 5679;
    server_name localhost;
    
    # Logs específicos para debug
    access_log /usr/local/var/log/nginx/n8n-proxy.access.log;
    error_log /usr/local/var/log/nginx/n8n-proxy.error.log;
    
    location / {
        # Proxy para n8n
        proxy_pass http://localhost:5678;
        
        # Headers de autenticação básica
        # admin@localhost:n8n123 em base64
        proxy_set_header Authorization "Basic YWRtaW5AbG9jYWxob3N0Om44bjEyMw==";
        
        # Headers padrão do proxy
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support (necessário para n8n)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffer sizes
        proxy_buffer_size 4k;
        proxy_buffers 4 32k;
        proxy_busy_buffers_size 64k;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
}
EOF

echo "✅ Configuração criada!"
echo ""

# Verificar se n8n está rodando
if ! curl -s http://localhost:5678 > /dev/null 2>&1; then
    echo "⚠️  n8n não está rodando. Iniciando..."
    ./scripts/n8n_no_auth_final.sh
    echo "⏳ Aguardando n8n iniciar..."
    sleep 15
fi

# Parar nginx se estiver rodando
echo "🔄 Reiniciando nginx..."
brew services stop nginx 2>/dev/null
sleep 2

# Iniciar nginx
brew services start nginx

echo ""
echo "⏳ Verificando proxy..."
sleep 3

# Testar proxy
if curl -s http://localhost:5679/health > /dev/null 2>&1; then
    echo "✅ Proxy reverso configurado com sucesso!"
    echo ""
    echo "🎉 ACESSO SEM AUTENTICAÇÃO DISPONÍVEL!"
    echo ""
    echo "🌐 Acesse n8n SEM LOGIN em:"
    echo "   http://localhost:5679"
    echo ""
    echo "📊 URLs disponíveis:"
    echo "   - n8n SEM auth: http://localhost:5679"
    echo "   - n8n original: http://localhost:5678 (requer login)"
    echo "   - Dashboard BullMQ: http://localhost:3001"
    echo ""
    echo "🔧 Comandos úteis:"
    echo "   - Ver logs: tail -f /usr/local/var/log/nginx/n8n-proxy.*.log"
    echo "   - Parar proxy: brew services stop nginx"
    echo "   - Status: brew services list | grep nginx"
    
    # Salvar informações
    cat > ~/.n8n/proxy_info.txt << 'EOF'
🔓 PROXY REVERSO N8N - ACESSO SEM LOGIN
========================================

URL SEM AUTENTICAÇÃO: http://localhost:5679

Como funciona:
- Nginx escuta na porta 5679
- Adiciona automaticamente header de autenticação
- Redireciona para n8n na porta 5678

Comandos:
- Iniciar: brew services start nginx
- Parar: brew services stop nginx
- Logs: tail -f /usr/local/var/log/nginx/n8n-proxy.*.log

Configuração: /usr/local/etc/nginx/servers/n8n-proxy.conf
EOF

    echo ""
    echo "📄 Informações salvas em: ~/.n8n/proxy_info.txt"
    
else
    echo "❌ Erro ao configurar proxy. Verificando logs..."
    tail -20 /usr/local/var/log/nginx/error.log
fi