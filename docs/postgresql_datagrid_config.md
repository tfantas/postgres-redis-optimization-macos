# Configuração PostgreSQL para DataGrip

## Credenciais do PostgreSQL Local

### Banco de dados principal (postgres)
- **Host**: localhost
- **Porta**: 5432
- **Usuário**: odin
- **Senha**: (deixar vazio)
- **Database**: postgres

### Banco de dados claude_memory
- **Host**: localhost
- **Porta**: 5432
- **Usuário**: claude
- **Senha**: (precisa descobrir - veja instruções abaixo)
- **Database**: claude_memory

## Como configurar no DataGrip

1. Abra o DataGrip
2. Clique em "+" ou "New" → "Data Source" → "PostgreSQL"
3. Configure a conexão:
   - **Name**: PostgreSQL Local
   - **Host**: localhost
   - **Port**: 5432
   - **User**: odin
   - **Password**: (deixar vazio)
   - **Database**: postgres
   - **URL** será gerada automaticamente: `jdbc:postgresql://localhost:5432/postgres`

4. Clique em "Test Connection" para verificar
5. Se tudo estiver OK, clique em "OK"

## Como acessar o banco claude_memory

Para acessar o banco `claude_memory`, você precisará:

1. Primeiro conectar como usuário `odin` no banco `postgres`
2. Executar este comando SQL para redefinir a senha do usuário `claude`:
   ```sql
   ALTER USER claude WITH PASSWORD 'nova_senha_aqui';
   ```

3. Depois criar uma nova conexão no DataGrip:
   - **Name**: Claude Memory DB
   - **Host**: localhost
   - **Port**: 5432
   - **User**: claude
   - **Password**: nova_senha_aqui
   - **Database**: claude_memory

## Alternativa: Usar DBeaver

Se preferir usar o DBeaver (gratuito e open source):

1. Abra o DBeaver
2. Clique em "New Database Connection" (ícone de plug com +)
3. Selecione "PostgreSQL"
4. Configure:
   - **Server Host**: localhost
   - **Port**: 5432
   - **Database**: postgres
   - **Username**: odin
   - **Password**: (deixar vazio)
   - Marque "Save password"

5. Clique em "Test Connection"
6. Se pedir para baixar drivers, clique em "Download"
7. Clique em "OK" ou "Finish"

## Comandos úteis no terminal

Para acessar o PostgreSQL via terminal:
```bash
# Conectar ao banco postgres
/usr/local/opt/postgresql@15/bin/psql -U odin -d postgres

# Listar todos os bancos
\l

# Conectar a outro banco
\c nome_do_banco

# Listar todas as tabelas
\dt

# Sair
\q
```

## Troubleshooting

Se tiver problemas de conexão:
1. Verifique se o PostgreSQL está rodando:
   ```bash
   brew services list | grep postgres
   ```

2. Se não estiver rodando:
   ```bash
   brew services start postgresql@15
   ```

3. Para ver os logs:
   ```bash
   tail -f /usr/local/var/log/postgresql@15.log
   ```