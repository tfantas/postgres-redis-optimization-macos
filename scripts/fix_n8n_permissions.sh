#!/bin/bash

echo "🔧 Corrigindo permissões do n8n..."
echo ""

# Verificar se o arquivo existe
if [ -f ~/.n8n/config ]; then
    echo "📁 Arquivo config encontrado"
    
    # Mostrar permissões atuais
    echo "Permissões atuais: $(ls -la ~/.n8n/config | awk '{print $1}')"
    
    # Corrigir permissões
    chmod 600 ~/.n8n/config
    
    echo "✅ Permissões corrigidas para 600 (leitura/escrita apenas para o proprietário)"
    echo "Novas permissões: $(ls -la ~/.n8n/config | awk '{print $1}')"
else
    echo "⚠️  Arquivo ~/.n8n/config não encontrado"
    echo "O n8n criará o arquivo na primeira execução"
fi

# Verificar se há outros arquivos com permissões muito abertas
echo ""
echo "🔍 Verificando outros arquivos n8n..."

if [ -d ~/.n8n ]; then
    find ~/.n8n -type f -perm -o+r -o -perm -o+w -o -perm -o+x 2>/dev/null | while read file; do
        echo "⚠️  Arquivo com permissões abertas: $file"
        chmod 600 "$file"
        echo "   ✅ Corrigido"
    done
fi

echo ""
echo "✨ Verificação de permissões concluída!"