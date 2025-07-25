#!/bin/bash

echo "🔧 Resolvendo conflitos de portas entre Docker e serviços nativos"
echo ""
echo "Escolha uma opção:"
echo "1) Parar containers Docker (usar apenas serviços nativos)"
echo "2) Parar serviços nativos (usar apenas Docker)"
echo "3) Mudar portas dos containers Docker"
echo ""
read -p "Opção (1-3): " opcao

case $opcao in
    1)
        echo "🛑 Parando containers Docker..."
        docker stop aix-postgres aix-redis
        echo "✅ Containers parados. Usando serviços nativos:"
        echo "   PostgreSQL: localhost:5432"
        echo "   Redis: localhost:6379"
        ;;
    2)
        echo "🛑 Parando serviços nativos..."
        brew services stop postgresql@15
        brew services stop redis
        echo "✅ Serviços nativos parados. Usando Docker:"
        echo "   PostgreSQL: localhost:5432 (Docker)"
        echo "   Redis: localhost:6379 (Docker)"
        ;;
    3)
        echo "🔄 Recriando containers com novas portas..."
        
        # Parar containers atuais
        docker stop aix-postgres aix-redis
        docker rm aix-postgres aix-redis
        
        # Recriar com novas portas
        docker run -d --name aix-postgres \
            -p 5433:5432 \
            -e POSTGRES_PASSWORD=postgres \
            postgres:latest
            
        docker run -d --name aix-redis \
            -p 6380:6379 \
            redis:latest
            
        echo "✅ Containers recriados com novas portas:"
        echo "   PostgreSQL nativo: localhost:5432"
        echo "   PostgreSQL Docker: localhost:5433"
        echo "   Redis nativo: localhost:6379"
        echo "   Redis Docker: localhost:6380"
        ;;
    *)
        echo "❌ Opção inválida"
        exit 1
        ;;
esac

echo ""
echo "📊 Status atual:"
echo "--- Serviços Nativos ---"
brew services list | grep -E "postgresql|redis"
echo ""
echo "--- Containers Docker ---"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "NAME|postgres|redis"