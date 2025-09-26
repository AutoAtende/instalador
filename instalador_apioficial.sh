#!/bin/bash


# Variaveis Padrão
ARCH=$(uname -m)
UBUNTU_VERSION=$(lsb_release -sr)
ARQUIVO_VARIAVEIS="VARIAVEIS_INSTALACAO"
ip_atual=$(curl -s http://checkip.amazonaws.com)
default_apioficial_port=6000

if [ "$EUID" -ne 0 ]; then
  echo
  printf " >> Este script precisa ser executado como root ou com privilégios de superusuário.\n"
  echo
  sleep 2
  exit 1
fi

# Função para manipular erros e encerrar o script
trata_erro() {
  printf "Erro encontrado na etapa $1. Encerrando o script.\n"
  exit 1
}

# Banner
banner() {
  clear
  printf ""
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║                    INSTALADOR API OFICIAL                    ║"
  echo "║                                                              ║"
  echo "║                    AutoAtende System                         ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  printf ""
  echo
}

# Carregar variáveis
carregar_variaveis() {
  if [ -f $ARQUIVO_VARIAVEIS ]; then
    source $ARQUIVO_VARIAVEIS
  else
    empresa="autoatende"
    nome_titulo="AutoAtende"
  fi
}

# Solicitar dados do subdomínio da API Oficial
solicitar_dados_apioficial() {
  banner
  printf " >> Insira o subdomínio da API Oficial: \n"
  echo
  read -p "> " subdominio_oficial
  echo
  printf "   Subdominio API Oficial: ---->> ${subdominio_oficial}\n"
  echo "subdominio_oficial=${subdominio_oficial}" >>$ARQUIVO_VARIAVEIS
}

# Validação de DNS
verificar_dns_apioficial() {
  banner
  printf " >> Verificando o DNS do subdomínio da API Oficial...\n"
  echo
  sleep 2
  sudo apt-get install dnsutils -y >/dev/null 2>&1

  local domain=${subdominio_oficial}
  local resolved_ip
  local cname_target

  cname_target=$(dig +short CNAME ${domain})

  if [ -n "${cname_target}" ]; then
    resolved_ip=$(dig +short ${cname_target})
  else
    resolved_ip=$(dig +short ${domain})
  fi

  if [ "${resolved_ip}" != "${ip_atual}" ]; then
    echo "O domínio ${domain} (resolvido para ${resolved_ip}) não está apontando para o IP público atual (${ip_atual})."
    echo
    printf " >> Verifique o apontamento de DNS do subdomínio: ${subdominio_oficial}\n"
    sleep 5
    exit 1
  else
    echo "Subdomínio ${domain} está apontando corretamente para o IP público da VPS."
    sleep 2
  fi
  echo
  printf " >> Continuando...\n"
  sleep 2
  echo
}

# Configurar Nginx para API Oficial
configurar_nginx_apioficial() {
  banner
  printf " >> Configurando Nginx para API Oficial...\n"
  echo
  {
    oficial_hostname=$(echo "${subdominio_oficial/https:\/\//}")
    sudo su - root <<EOF
cat > /etc/nginx/sites-available/${empresa}-oficial << 'END'
upstream oficial {
        server 127.0.0.1:${default_apioficial_port};
        keepalive 32;
    }
server {
  server_name ${oficial_hostname};
  location / {
    proxy_pass http://oficial;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_cache_bypass \$http_upgrade;
    proxy_buffering on;
  }
}
END
ln -s /etc/nginx/sites-available/${empresa}-oficial /etc/nginx/sites-enabled
EOF

    sleep 2

    banner
    printf " >> Emitindo SSL do ${subdominio_oficial}...\n"
    echo
    oficial_domain=$(echo "${subdominio_oficial/https:\/\//}")
    sudo su - root <<EOF
    certbot -m ${email_deploy} \
            --nginx \
            --agree-tos \
            -n \
            -d ${oficial_domain}
EOF

    sleep 2
  } || trata_erro "configurar_nginx_apioficial"
}

# Criar banco de dados para API Oficial
criar_banco_apioficial() {
  banner
  printf " >> Criando banco de dados para API Oficial...\n"
  echo
  {
    sudo -u postgres psql <<EOF
CREATE DATABASE oficialseparado;
\q
EOF
    printf " >> Banco de dados 'oficialseparado' criado com sucesso!\n"
    sleep 2
  } || trata_erro "criar_banco_apioficial"
}

# Configurar arquivo .env da API Oficial
configurar_env_apioficial() {
  banner
  printf " >> Configurando arquivo .env da API Oficial...\n"
  echo
  {
    # Carregar variáveis necessárias
    source $ARQUIVO_VARIAVEIS
    
    # Buscar JWT_REFRESH_SECRET do backend existente
    jwt_refresh_secret_backend=$(grep "^JWT_REFRESH_SECRET=" /home/deploy/${empresa}/backend/.env | cut -d '=' -f2-)
    
    # Buscar BACKEND_URL do backend existente
    backend_url=$(grep "^BACKEND_URL=" /home/deploy/${empresa}/backend/.env | cut -d '=' -f2-)
    
    # Criar diretório da API Oficial se não existir
    mkdir -p /home/deploy/${empresa}/api_oficial
    
    # Criar arquivo .env
    cat > /home/deploy/${empresa}/api_oficial/.env <<EOF
DATABASE_LINK=postgresql://${empresa}:${senha_deploy}@localhost:5432/oficialseparado?schema=public
DATABASE_URL=localhost
DATABASE_PORT=5432
DATABASE_USER=${empresa}
DATABASE_PASSWORD=${senha_deploy}
DATABASE_NAME=oficialseparado
TOKEN_ADMIN=adminpro
URL_BACKEND_AUTOATENDE=https://${subdominio_backend}
REDIS_URI=redis://:${senha_deploy}@127.0.0.1:6379
PORT=${default_apioficial_port}
NAME_ADMIN=SetupAutomatizado
EMAIL_ADMIN=admin@autoatende.com.br
PASSWORD_ADMIN=adminpro
JWT_REFRESH_SECRET=${jwt_refresh_secret_backend}
URL_API_OFICIAL=https://${subdominio_oficial}
EOF

    printf " >> Arquivo .env da API Oficial configurado com sucesso!\n"
    sleep 2
  } || trata_erro "configurar_env_apioficial"
}

# Instalar e configurar API Oficial
instalar_apioficial() {
  banner
  printf " >> Instalando e configurando API Oficial...\n"
  echo
  {
    sudo su - deploy <<EOF
cd /home/deploy/${empresa}/api_oficial

printf " >> Instalando dependências...\n"
npm install

printf " >> Gerando Prisma...\n"
npx prisma generate

printf " >> Buildando aplicação...\n"
npm run build

printf " >> Executando migrações...\n"
npx prisma migrate dev

printf " >> Gerando cliente Prisma...\n"
npx prisma generate client

printf " >> Iniciando aplicação com PM2...\n"
pm2 start dist/main.js --name=api_oficial

printf " >> API Oficial instalada e configurada com sucesso!\n"
sleep 2
EOF
  } || trata_erro "instalar_apioficial"
}

# Atualizar .env do backend com URL da API Oficial
atualizar_env_backend() {
  banner
  printf " >> Atualizando .env do backend com URL da API Oficial...\n"
  echo
  {
    # Adicionar URL_API_OFICIAL ao .env do backend
    echo "URL_API_OFICIAL=https://${subdominio_oficial}" >> /home/deploy/${empresa}/backend/.env
    
    printf " >> .env do backend atualizado com sucesso!\n"
    sleep 2
  } || trata_erro "atualizar_env_backend"
}

# Reiniciar serviços
reiniciar_servicos() {
  banner
  printf " >> Reiniciando serviços...\n"
  echo
  {
    sudo su - root <<EOF
    if systemctl is-active --quiet nginx; then
      sudo systemctl restart nginx
    else
      printf "Nginx não está em execução."
    fi
EOF

    printf " >> Serviços reiniciados com sucesso!\n"
    sleep 2
  } || trata_erro "reiniciar_servicos"
}

# Função principal
main() {
  carregar_variaveis
  solicitar_dados_apioficial
  verificar_dns_apioficial
  configurar_nginx_apioficial
  criar_banco_apioficial
  configurar_env_apioficial
  instalar_apioficial
  atualizar_env_backend
  reiniciar_servicos
  
  banner
  printf " >> Instalação da API Oficial concluída com sucesso!\n"
  echo
  printf " >> API Oficial disponível em: https://${subdominio_oficial}\n"
  printf " >> Porta da API Oficial: ${default_apioficial_port}\n"
  echo
  sleep 5
}

# Executar função principal
main
