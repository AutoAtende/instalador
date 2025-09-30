#!/bin/bash


# Variaveis Padrão
ARCH=$(uname -m)
UBUNTU_VERSION=$(lsb_release -sr)
ARQUIVO_VARIAVEIS="VARIAVEIS_INSTALACAO"
ARQUIVO_ETAPAS="ETAPA_INSTALACAO"
FFMPEG="$(pwd)/ffmpeg.x"
FFMPEG_DIR="$(pwd)/ffmpeg"
ip_atual=$(curl -s http://checkip.amazonaws.com)
jwt_secret=$(openssl rand -base64 32)
jwt_refresh_secret=$(openssl rand -base64 32)

if [ "$EUID" -ne 0 ]; then
  echo
  printf " >> Este script precisa ser executado como root ou com privilégios de superusuário.\n"
  echo
  sleep 2
  exit 1
fi

banner() {
  printf "\n\n"
  printf "██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     ███████╗██╗    ██╗██╗\n"
  printf "██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     ██╔════╝██║    ██║██║\n"
  printf "██║██╔██╗ ██║███████    ██║   ███████║██║     ██║     ███████╗██║ █╗ ██║██║\n"
  printf "██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     ╚════██║██║███╗██║██║\n"
  printf "██║██║ ╚████║███████╗   ██║   ██║  ██║███████╗███████╗███████╗╚███╔███╔╝███████╗\n"
  printf "╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝ ╚══╝╚══╝ ╚══════╝\n"
  printf "                                INSTALADOR 3.0\n"
  printf "\n\n"
}

# Função para manipular erros e encerrar o script
trata_erro() {
  printf "Erro encontrado na etapa $1. Encerrando o script.\n"
  salvar_etapa "$1"
  exit 1
}

# Salvar variáveis
salvar_variaveis() {
  echo "subdominio_backend=${subdominio_backend}" >$ARQUIVO_VARIAVEIS
  echo "subdominio_frontend=${subdominio_frontend}" >>$ARQUIVO_VARIAVEIS
  echo "email_deploy=${email_deploy}" >>$ARQUIVO_VARIAVEIS
  echo "empresa=${empresa}" >>$ARQUIVO_VARIAVEIS
  echo "senha_deploy=${senha_deploy}" >>$ARQUIVO_VARIAVEIS
  # echo "subdominio_perfex=${subdominio_perfex}" >>$ARQUIVO_VARIAVEIS
  echo "senha_master=${senha_master}" >>$ARQUIVO_VARIAVEIS
  echo "nome_titulo=${nome_titulo}" >>$ARQUIVO_VARIAVEIS
  echo "numero_suporte=${numero_suporte}" >>$ARQUIVO_VARIAVEIS
  echo "facebook_app_id=${facebook_app_id}" >>$ARQUIVO_VARIAVEIS
  echo "facebook_app_secret=${facebook_app_secret}" >>$ARQUIVO_VARIAVEIS
  echo "github_token=${github_token}" >>$ARQUIVO_VARIAVEIS
  echo "repo_url=${repo_url}" >>$ARQUIVO_VARIAVEIS
  echo "proxy=${proxy}" >>$ARQUIVO_VARIAVEIS
  echo "backend_port=${backend_port}" >>$ARQUIVO_VARIAVEIS
  echo "frontend_port=${frontend_port}" >>$ARQUIVO_VARIAVEIS
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

# Salvar etapa concluída
salvar_etapa() {
  echo "$1" >$ARQUIVO_ETAPAS
}

# Carregar última etapa
carregar_etapa() {
  if [ -f $ARQUIVO_ETAPAS ]; then
    etapa=$(cat $ARQUIVO_ETAPAS)
    if [ -z "$etapa" ]; then
      etapa="0"
    fi
  else
    etapa="0"
  fi
}

# Resetar etapas e variáveis
resetar_instalacao() {
  rm -f $ARQUIVO_VARIAVEIS $ARQUIVO_ETAPAS
  printf " >> Instalação resetada! Iniciando uma nova instalação...\n"
  sleep 2
  instalacao_base
}

# Pergunta se deseja continuar ou recomeçar
verificar_arquivos_existentes() {
  if [ -f $ARQUIVO_VARIAVEIS ] && [ -f $ARQUIVO_ETAPAS ]; then
    banner
    printf " >> Dados de instalação anteriores detectados.\n"
    echo
    carregar_etapa
    if [ "$etapa" -eq 20 ]; then
      printf ">> Instalação já concluída.\n"
      printf ">> Deseja resetar as etapas e começar do zero? (S/N): \n"
      echo
      read -p "> " reset_escolha
      echo
      reset_escolha=$(echo "${reset_escolha}" | tr '[:lower:]' '[:upper:]')
      if [ "$reset_escolha" == "S" ]; then
        resetar_instalacao
      else
        printf " >> Voltando para o menu principal...\n"
        sleep 2
        menu
      fi
    elif [ "$etapa" -lt 20 ]; then
      printf " >> Instalação Incompleta Detectada na etapa $etapa. \n"
      printf " >> Deseja continuar de onde parou? (S/N): \n"
      echo
      read -p "> " escolha
      echo
      escolha=$(echo "${escolha}" | tr '[:lower:]' '[:upper:]')
      if [ "$escolha" == "S" ]; then
        instalacao_base
      else
        printf " >> Voltando ao menu principal...\n"
        printf " >> Caso deseje resetar as etapas, apague os arquivos ETAPAS_INSTALAÇÃO da pasta root...\n"
        sleep 5
        menu
      fi
    fi
  else
    instalacao_base
  fi
}

# Menu principal
menu() {
  while true; do
    banner
    printf " Selecione abaixo a opção desejada: \n"
    echo
    printf "   [1] Instalar ${nome_titulo}\n"
    printf "   [2] Atualizar ${nome_titulo}\n"
    printf "   [3] Instalar Transcrição de Audio Nativa\n"
    printf "   [4] Instalar API Oficial\n"
    printf "   [0] Sair\n"
    echo
    read -p "> " option
    case "${option}" in
    1)
      verificar_arquivos_existentes
      ;;
    2)
      atualizar_base
      ;;
    3)
      instalar_transcricao_audio_nativa
      ;;
    4)
      instalar_api_oficial
      ;;
    0)
      sair
      ;;
    *)
      printf "Opção inválida. Tente novamente."
      sleep 2
      ;;
    esac
  done
}

# Etapa de instalação
instalacao_base() {
  carregar_etapa
  if [ "$etapa" == "0" ]; then
    questoes_dns_base || trata_erro "questoes_dns_base"
    verificar_dns_base || trata_erro "verificar_dns_base"
    questoes_variaveis_base || trata_erro "questoes_variaveis_base"
    define_proxy_base || trata_erro "define_proxy_base"
    define_portas_base || trata_erro "define_portas_base"
    confirma_dados_instalacao_base || trata_erro "confirma_dados_instalacao_base"
    salvar_variaveis || trata_erro "salvar_variaveis"
    salvar_etapa 1
  fi
  if [ "$etapa" -le "1" ]; then
    atualiza_vps_base || trata_erro "atualiza_vps_base"
    salvar_etapa 2
  fi
  if [ "$etapa" -le "2" ]; then
    cria_deploy_base || trata_erro "cria_deploy_base"
    salvar_etapa 3
  fi
  if [ "$etapa" -le "3" ]; then
    config_timezone_base || trata_erro "config_timezone_base"
    salvar_etapa 4
  fi
  if [ "$etapa" -le "4" ]; then
    config_firewall_base || trata_erro "config_firewall_base"
    salvar_etapa 5
  fi
  if [ "$etapa" -le "5" ]; then
    instala_ffmpeg_base || trata_erro "instala_ffmpeg_base"
    salvar_etapa 6
  fi
  if [ "$etapa" -le "6" ]; then
    instala_postgres_base || trata_erro "instala_postgres_base"
    salvar_etapa 7
  fi
  if [ "$etapa" -le "7" ]; then
    instala_node_base || trata_erro "instala_node_base"
    salvar_etapa 8
  fi
  if [ "$etapa" -le "8" ]; then
    instala_redis_base || trata_erro "instala_redis_base"
    salvar_etapa 9
  fi
  if [ "$etapa" -le "9" ]; then
    instala_pm2_base || trata_erro "instala_pm2_base"
    salvar_etapa 10
  fi
  if [ "$etapa" -le "10" ]; then
    if [ "${proxy}" == "nginx" ]; then
      instala_nginx_base || trata_erro "instala_nginx_base"
      salvar_etapa 11
      salvar_etapa 11
    fi
  fi
  if [ "$etapa" -le "11" ]; then
    cria_banco_base || trata_erro "cria_banco_base"
    salvar_etapa 12
  fi
  if [ "$etapa" -le "12" ]; then
    instala_git_base || trata_erro "instala_git_base"
    salvar_etapa 13
  fi
  if [ "$etapa" -le "13" ]; then
    codifica_clone_base || trata_erro "codifica_clone_base"
    baixa_codigo_base || trata_erro "baixa_codigo_base"
    salvar_etapa 14
  fi
  if [ "$etapa" -le "14" ]; then
    instala_backend_base || trata_erro "instala_backend_base"
    salvar_etapa 15
  fi
  if [ "$etapa" -le "15" ]; then
    instala_frontend_base || trata_erro "instala_frontend_base"
    salvar_etapa 16
  fi
  if [ "$etapa" -le "16" ]; then
    salvar_etapa 17
  fi
  if [ "$etapa" -le "17" ]; then
    if [ "${proxy}" == "nginx" ]; then
      config_nginx_base || trata_erro "config_nginx_base"
      salvar_etapa 18
      salvar_etapa 18
    fi
  fi
  if [ "$etapa" -le "18" ]; then
    config_latencia_base || trata_erro "config_latencia_base"
    salvar_etapa 19
  fi
  if [ "$etapa" -le "19" ]; then
    fim_instalacao_base || trata_erro "fim_instalacao_base"
    salvar_etapa 20
  fi
}

# Etapa de instalação
atualizar_base() {
  instala_ffmpeg_base || trata_erro "instala_ffmpeg_base"
}

sair() {
  exit 0
}

################################################################
#                         INSTALAÇÃO                           #
################################################################

# Questões base
questoes_dns_base() {
  # ARMAZENA URL BACKEND
  banner
  printf " >> Insira a URL do Backend: \n"
  echo
  read -p "> " subdominio_backend
  echo
  # ARMAZENA URL FRONTEND
  banner
  printf " >> Insira a URL do Frontend: \n"
  echo
  read -p "> " subdominio_frontend
  echo
}

# Valida se o domínio ou subdomínio está apontado para o IP da VPS
verificar_dns_base() {
  banner
  printf " >> Verificando o DNS dos dominios/subdominios...\n"
  echo
  sleep 2
  sudo apt-get install dnsutils -y >/dev/null 2>&1
  subdominios_incorretos=""

  verificar_dns() {
    local domain=$1
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
      subdominios_incorretos+="${domain} "
      sleep 2
    fi
  }
  verificar_dns ${subdominio_backend}
  verificar_dns ${subdominio_frontend}
  if [ -n "${subdominios_incorretos}" ]; then
    echo
    echo "Verifique os apontamentos de DNS dos seguintes subdomínios: ${subdominios_incorretos}"
    sleep 2
    menu
    return 0
  else
    echo "Todos os subdomínios estão apontando corretamente para o IP público da VPS."
    sleep 2
  fi
  echo
  printf " >> Continuando...\n"
  sleep 2
  echo
}

questoes_variaveis_base() {
  # DEFINE EMAIL
  banner
  printf " >> Digite o seu melhor email: \n"
  echo
  read -p "> " email_deploy
  echo
  # DEFINE NOME DA EMPRESA
  banner
  printf " >> Digite o nome da sua empresa (Letras minusculas e sem espaço): \n"
  echo
  read -p "> " empresa
  echo
  # DEFINE SENHA BASE
  banner
  printf " >> Insira a senha para o usuario Deploy, Redis e Banco de Dados IMPORTANTE: Não utilizar caracteres especiais\n"
  echo
  read -p "> " senha_deploy
  echo
  # ARMAZENA URL BACKEND
  # banner
  # printf " >> Insira a URL do PerfexCRM: \n"
  # echo
  # read -p "> " subdominio_perfex
  echo
  # DEFINE SENHA MASTER
  banner
  printf " >> Insira a senha para o MASTER: \n"
  echo
  read -p "> " senha_master
  echo
  # DEFINE TITULO DO APP NO NAVEGADOR
  banner
  printf " >> Insira o Titulo da Aplicação (Permitido Espaço): \n"
  echo
  read -p "> " nome_titulo
  echo
  # DEFINE TELEFONE SUPORTE
  banner
  printf " >> Digite o numero de telefone para suporte: \n"
  echo
  read -p "> " numero_suporte
  echo
  # DEFINE FACEBOOK_APP_ID
  banner
  printf " >> Digite o FACEBOOK_APP_ID caso tenha: \n"
  echo
  read -p "> " facebook_app_id
  echo
  # DEFINE FACEBOOK_APP_SECRET
  banner
  printf " >> Digite o FACEBOOK_APP_SECRET caso tenha: \n"
  echo
  read -p "> " facebook_app_secret
  echo
  # DEFINE TOKEN GITHUB
  banner
  printf " >> Digite seu TOKEN de acesso pessoal do GitHub: \n"
  printf " >> Passo a Passo para gerar o seu TOKEN no link https://bit.ly/token-github \n"
  echo
  read -p "> " github_token
  echo
  # DEFINE LINK REPO GITHUB
  banner
  printf " >> Digite a URL do repositório privado no GitHub: \n"
  echo
  read -p "> " repo_url
  echo
}

# Define proxy usado
define_proxy_base() {
  proxy="nginx"
  export proxy
}

# Define portas backend e frontend
define_portas_base() {
  banner
  printf " >> Usar as portas padrão para Backend (8080) e Frontend (3000) ? (S/N): \n"
  echo
  read -p "> " use_default_ports
  use_default_ports=$(echo "${use_default_ports}" | tr '[:upper:]' '[:lower:]')
  echo

  default_backend_port=8080
  default_frontend_port=3000

  if [ "${use_default_ports}" = "s" ]; then
    backend_port=${default_backend_port}
    frontend_port=${default_frontend_port}
  else
    while true; do
      printf " >> Qual porta deseja para o Backend? \n"
      echo
      read -p "> " backend_port
      echo
      if ! lsof -i:${backend_port} &>/dev/null; then
        break
      else
        printf " >> A porta ${backend_port} já está em uso. Por favor, escolha outra.\n"
        echo
      fi
    done

    while true; do
      printf " >> Qual porta deseja para o Frontend? \n"
      echo
      read -p "> " frontend_port
      echo
      if ! lsof -i:${frontend_port} &>/dev/null; then
        break
      else
        printf " >> A porta ${frontend_port} já está em uso. Por favor, escolha outra.\n"
        echo
      fi
    done
  fi

  sleep 2
}

# Informa os dados de instalação
dados_instalacao_base() {
  printf "   Anote os dados abaixo\n\n"
  printf "   Subdominio Backend: ---->> ${subdominio_backend}\n"
  printf "   Subdominiio Frontend: -->> ${subdominio_frontend}\n"
  printf "   Seu Email: ------------->> ${email_deploy}\n"
  printf "   Nome da Empresa: ------->> ${empresa}\n"
  printf "   Senha Deploy: ---------->> ${senha_deploy}\n"
  # printf "   Subdominio Perfex: ----->> ${subdominio_perfex}\n"
  printf "   Senha Master: ---------->> ${senha_master}\n"
  printf "   Titulo da Aplicação: --->> ${nome_titulo}\n"
  printf "   Numero de Suporte: ----->> ${numero_suporte}\n"
  printf "   FACEBOOK_APP_ID: ------->> ${facebook_app_id}\n"
  printf "   FACEBOOK_APP_SECRET: --->> ${facebook_app_secret}\n"
  printf "   Token GitHub: ---------->> ${github_token}\n"
  printf "   URL do Repositório: ---->> ${repo_url}\n"
  printf "   Proxy Usado: ----------->> ${proxy}\n"
  printf "   Porta Backend: --------->> ${backend_port}\n"
  printf "   Porta Frontend: -------->> ${frontend_port}\n"
}

# Confirma os dados de instalação
confirma_dados_instalacao_base() {
  printf " >> Confira abaixo os dados dessa instalação! \n"
  echo
  dados_instalacao_base
  echo
  printf " >> Os dados estão corretos? S/N: \n"
  echo
  read -p "> " confirmacao
  echo
  confirmacao=$(echo "${confirmacao}" | tr '[:lower:]' '[:upper:]')
  if [ "${confirmacao}" == "S" ]; then
    printf " >> Continuando a Instalação... \n"
    echo
  else
    printf " >> Retornando ao Menu Principal... \n"
    echo
    sleep 2
    menu
  fi
}

# Atualiza sistema operacional
atualiza_vps_base() {
  UPDATE_FILE="$(pwd)/update.x"
  {
    sudo DEBIAN_FRONTEND=noninteractive apt update -y && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" && sudo DEBIAN_FRONTEND=noninteractive apt-get install build-essential -y && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y apparmor-utils
    touch "${UPDATE_FILE}"
    sleep 2
  } || trata_erro "atualiza_vps_base"
}

# Cria usuário deploy
cria_deploy_base() {
  banner
  printf " >> Agora, vamos criar o usuário para deploy...\n"
  echo
  {
    sudo useradd -m -p $(openssl passwd -1 ${senha_deploy}) -s /bin/bash -G sudo deploy
    sudo usermod -aG sudo deploy
    sleep 2
  } || trata_erro "cria_deploy_base"
}

# Configura timezone
config_timezone_base() {
  banner
  printf " >> Configurando Timezone...\n"
  echo
  {
    sudo su - root <<EOF
  timedatectl set-timezone America/Sao_Paulo
EOF
    sleep 2
  } || trata_erro "config_timezone_base"
}

# Configura firewall
config_firewall_base() {
  banner
  printf " >> Configurando o firewall Portas 80 e 443...\n"
  echo
  {
    if [ "${ARCH}" = "x86_64" ]; then
      sudo su - root <<EOF >/dev/null 2>&1
  ufw allow 80/tcp && ufw allow 22/tcp && ufw allow 443/tcp
EOF
      sleep 2

    elif [ "${ARCH}" = "aarch64" ]; then
      sudo su - root <<EOF >/dev/null 2>&1
  sudo iptables -F &&
  sudo iptables -A INPUT -i lo -j ACCEPT &&
  sudo iptables -A OUTPUT -o lo -j ACCEPT &&
  sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT &&
  sudo iptables -A INPUT -p udp --dport 80 -j ACCEPT &&
  sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT &&
  sudo iptables -A INPUT -p udp --dport 443 -j ACCEPT &&
  sudo service netfilter-persistent save
EOF
      sleep 2

    else
      echo "Arquitetura não suportada."
    fi
  } || trata_erro "config_firewall_base"
}

# Instala FFMPEG
instala_ffmpeg_base() {
  banner
  printf " >> Instalando FFMPEG...\n"
  echo
  {
    sudo apt install ffmpeg -y
    sleep 2
  } || trata_erro "instala_ffmpeg_base"
}

# Instala Postgres
instala_postgres_base() {
  banner
  printf " >> Instalando postgres...\n"
  echo
  {
    sudo su - root <<EOF
  sudo apt-get install gnupg -y
  sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  sudo apt-get update -y && sudo apt-get -y install postgresql-17
EOF
    sleep 2
  } || trata_erro "instala_postgres_base"
}

Instala NodeJS
instala_node_base() {
  banner
 printf " >> Instalando nodejs...\n"
 echo
  {
    sudo su - root <<EOF
  curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
  sudo sh -c "echo deb https://deb.nodesource.com/node_20.x focal main \ > /etc/apt/sources.list.d/nodesource.list"
  sudo apt-get update && apt-get install nodejs -y
  sudo npm install -g n
  sudo n 20.19.4
  sudo ln -sf /usr/local/n/versions/node/20.19.4/bin/node /usr/bin/node
  sudo ln -sf /usr/local/n/versions/node/20.19.4/bin/npm /usr/bin/npm
EOF
    sleep 2
  } || trata_erro "instala_node_base"
}

# Instala Redis
instala_redis_base() {
  {
    sudo su - root <<EOF
  apt install redis-server -y
  systemctl enable redis-server.service
  sed -i 's/# requirepass foobared/requirepass ${senha_deploy}/g' /etc/redis/redis.conf
  sed -i 's/^appendonly no/appendonly yes/g' /etc/redis/redis.conf
  systemctl restart redis-server.service
EOF
    sleep 2
  } || trata_erro "instala_redis_base"
}

# Instala PM2
instala_pm2_base() {
  banner
  printf " >> Instalando pm2...\n"
  echo
  {
    sudo su - root <<EOF
  npm install -g pm2
  pm2 startup ubuntu -u deploy
  env PATH=\${PATH}:/usr/bin pm2 startup ubuntu -u deploy --hp /home/deploy
EOF
    sleep 2
  } || trata_erro "instala_pm2_base"
}

# Instala Nginx e dependências
instala_nginx_base() {
  banner
  printf " >> Instalando Nginx...\n"
  echo
  {
    sudo su - root <<EOF
    apt install -y nginx
    rm /etc/nginx/sites-enabled/default
EOF

    sleep 2

    sudo su - root <<EOF
echo 'client_max_body_size 100M;' > /etc/nginx/conf.d/${empresa}.conf
EOF

    sleep 2

    sudo su - root <<EOF
  service nginx restart
EOF

    sleep 2

    sudo su - root <<EOF
  apt install -y snapd
  snap install core
  snap refresh core
EOF

    sleep 2

    sudo su - root <<EOF
  apt-get remove certbot
  snap install --classic certbot
  ln -s /snap/bin/certbot /usr/bin/certbot
EOF

    sleep 2
  } || trata_erro "instala_nginx_base"
}


# Cria banco de dados
cria_banco_base() {
  banner
  printf " >> Criando Banco Postgres...\n"
  echo
  {
    sudo su - postgres <<EOF
    createdb ${empresa};
    psql
    CREATE USER ${empresa} SUPERUSER INHERIT CREATEDB CREATEROLE;
    ALTER USER ${empresa} PASSWORD '${senha_deploy}';
    \q
    exit
EOF

    sleep 2
  } || trata_erro "cria_banco_base"
}

# Instala Git
instala_git_base() {
  banner
  printf " >> Instalando o GIT...\n"
  echo
  {
    sudo su - root <<EOF
  apt install -y git
  apt -y autoremove
EOF
    sleep 2
  } || trata_erro "instala_git_base"
}

# Função para codificar URL de clone
codifica_clone_base() {
  local length="${#1}"
  for ((i = 0; i < length; i++)); do
    local c="${1:i:1}"
    case $c in
    [a-zA-Z0-9.~_-]) printf "$c" ;;
    *) printf '%%%02X' "'$c" ;;
    esac
  done
}

# Clona código de repo privado
baixa_codigo_base() {
  banner
  printf " >> Fazendo download do ${nome_titulo}...\n"
  echo
  {
    if [ -z "${repo_url}" ] || [ -z "${github_token}" ]; then
      printf " >> Erro: URL do repositório ou token do GitHub não definidos.\n"
      exit 1
    fi

    github_token_encoded=$(codifica_clone_base "${github_token}")
    github_url=$(echo ${repo_url} | sed "s|https://|https://${github_token_encoded}@|")

    dest_dir="/home/deploy/${empresa}/"

    git clone ${github_url} ${dest_dir}
    echo
    if [ $? -eq 0 ]; then
      printf " >> Código baixado, continuando a instalação...\n"
      echo
    else
      printf " >> Falha ao baixar o código! Verifique as informações fornecidas...\n"
      echo
      exit 1
    fi

    mkdir -p /home/deploy/${empresa}/backend/public/
    chown deploy:deploy -R /home/deploy/${empresa}/
    chmod 775 -R /home/deploy/${empresa}/backend/public/
    sleep 2
  } || trata_erro "baixa_codigo_base"
}

# Instala e configura backend
instala_backend_base() {
  banner
  printf " >> Configurando variáveis de ambiente do backend...\n"
  echo
  {
    sleep 2
    subdominio_backend=$(echo "${subdominio_backend/https:\/\//}")
    subdominio_backend=${subdominio_backend%%/*}
    subdominio_backend=https://${subdominio_backend}
    subdominio_frontend=$(echo "${subdominio_frontend/https:\/\//}")
    subdominio_frontend=${subdominio_frontend%%/*}
    subdominio_frontend=https://${subdominio_frontend}
    # subdominio_perfex=$(echo "${subdominio_perfex/https:\/\//}")
    # subdominio_perfex=${subdominio_perfex%%/*}
    # subdominio_perfex=https://${subdominio_perfex}
    sudo su - deploy <<EOF
  cat <<[-]EOF > /home/deploy/${empresa}/backend/.env
# Scripts WhiteLabel - All Rights Reserved - (18) 9 8802-9627
NODE_ENV=
BACKEND_URL=${subdominio_backend}
FRONTEND_URL=${subdominio_frontend}
PROXY_PORT=443
PORT=${backend_port}

# CREDENCIAIS BD
DB_HOST=localhost
DB_DIALECT=postgres
DB_PORT=5432
DB_USER=${empresa}
DB_PASS=${senha_deploy}
DB_NAME=${empresa}

# DADOS REDIS
REDIS_URI=redis://:${senha_deploy}@127.0.0.1:6379
REDIS_OPT_LIMITER_MAX=1
REDIS_OPT_LIMITER_DURATION=3000
# REDIS_URI_ACK=redis://:${senha_deploy}@127.0.0.1:6379
# BULL_BOARD=true
# BULL_USER=${email_deploy}
# BULL_PASS=${senha_deploy}

TIMEOUT_TO_IMPORT_MESSAGE=1000

# SECRETS
JWT_SECRET=${jwt_secret}
JWT_REFRESH_SECRET=${jwt_refresh_secret}
MASTER_KEY=${senha_master}

# PERFEX_URL=${subdominio_perfex}
# PERFEX_MODULE=Multi100
VERIFY_TOKEN=whaticket
FACEBOOK_APP_ID=${facebook_app_id}
FACEBOOK_APP_SECRET=${facebook_app_secret}

#METODOS DE PAGAMENTO

STRIPE_PRIVATE=
STRIPE_OK_URL=BACKEND_URL/subscription/stripewebhook
STRIPE_CANCEL_URL=FRONTEND_URL/financeiro

# MERCADO PAGO

MPACCESSTOKEN=SEU TOKEN
MPNOTIFICATIONURL=https://SUB_DOMINIO_API/subscription/mercadopagowebhook

MP_ACCESS_TOKEN=SEU TOKEN
MP_NOTIFICATION_URL=https://SUB_DOMINIO_API/subscription/mercadopagowebhook

ASAAS_TOKEN=SEU TOKEN
MP_NOTIFICATION_URL=https://SUB_DOMINIO_API/subscription/asaaswebhook

MPNOTIFICATION_URL=https://SUB_DOMINIO_API/subscription/asaaswebhook
ASAASTOKEN=SEU TOKEN

GERENCIANET_SANDBOX=
GERENCIANET_CLIENT_ID=
GERENCIANET_CLIENT_SECRET=
GERENCIANET_PIX_CERT=
GERENCIANET_PIX_KEY=

# EMAIL
MAIL_HOST="smtp.gmail.com"
MAIL_USER="SEUGMAIL@gmail.com"
MAIL_PASS="SENHA DE APP"
MAIL_FROM="Recuperação de Senha <SEU GMAIL@gmail.com>"
MAIL_PORT="465"

# WhatsApp Oficial
USE_WHATSAPP_OFICIAL=true
# URL_API_OFICIAL=https://SubDominioDaOficial.SEUDOMINIO.com.br
TOKEN_API_OFICIAL="adminpro"

# API de Transcrição de Audio
TRANSCRIBE_URL=http://localhost:4002
[-]EOF
EOF

    sleep 2

    banner
    printf " >> Instalando dependências do backend...\n"
    echo
    sudo su - deploy <<EOF
  cd /home/deploy/${empresa}/backend
  export PUPPETEER_SKIP_DOWNLOAD=true
  rm -r node_modules
  rm package-lock.json
  npm install --force
  npm install puppeteer-core --force
  # npm install --save-dev @types/glob --legacy-peer-deps
  npm i glob
  # npm install jimp@^1.6.0
  npm run build
EOF

    sleep 2

    sudo su - deploy <<EOF
  sed -i 's|npm3Binary = .*|npm3Binary = "/usr/bin/ffmpeg";|' ${empresa}/backend/node_modules/@ffmpeg-installer/ffmpeg/index.js
  mkdir -p /home/deploy/${empresa}/backend/node_modules/@ffmpeg-installer/linux-x64/ && \
  echo '{ "version": "1.1.0", "name": "@ffmpeg-installer/linux-x64" }' > ${empresa}/backend/node_modules/@ffmpeg-installer/linux-x64/package.json
EOF

    sleep 2

    banner
    printf " >> Executando db:migrate...\n"
    echo
    sudo su - deploy <<EOF
  cd /home/deploy/${empresa}/backend
  npx sequelize db:migrate
EOF

    sleep 2

    banner
    printf " >> Executando db:seed...\n"
    echo
    sudo su - deploy <<EOF
  cd /home/deploy/${empresa}/backend
  npx sequelize db:seed:all
EOF

    sleep 2

    banner
    printf " >> Iniciando pm2 backend...\n"
    echo
    sudo su - deploy <<EOF
  cd /home/deploy/${empresa}/backend
  pm2 start dist/server.js --name ${empresa}-backend
EOF

    sleep 2
  } || trata_erro "instala_backend_base"
}

# Instala e configura frontend
instala_frontend_base() {
  banner
  printf " >> Instalando dependências do frontend...\n"
  echo
  {
    sudo su - deploy <<EOF
  cd /home/deploy/${empresa}/frontend
  npm install --force
  npx browserslist@latest --update-db
EOF

    sleep 2

    banner
    printf " >> Configurando variáveis de ambiente frontend...\n"
    echo
    subdominio_backend=$(echo "${subdominio_backend/https:\/\//}")
    subdominio_backend=${subdominio_backend%%/*}
    subdominio_backend=https://${subdominio_backend}
    frontend_chatbot_url=$(echo "${frontend_chatbot_url/https:\/\//}")
    frontend_chatbot_url=${frontend_chatbot_url%%/*}
    frontend_chatbot_url=https://${frontend_chatbot_url}
    sudo su - deploy <<EOF
  cat <<[-]EOF > /home/deploy/${empresa}/frontend/.env
REACT_APP_BACKEND_URL=${subdominio_backend}
REACT_APP_FACEBOOK_APP_ID=${facebook_app_id}
REACT_APP_REQUIRE_BUSINESS_MANAGEMENT=TRUE
REACT_APP_NAME_SYSTEM=${nome_titulo}
REACT_APP_NUMBER_SUPPORT=${numero_suporte}
SERVER_PORT=${frontend_port}
[-]EOF
EOF

    sleep 2

    banner
    printf " >> Compilando o código do frontend...\n"
    echo
    sudo su - deploy <<EOF
    cd /home/deploy/${empresa}/frontend
    sed -i 's/3000/'"${frontend_port}"'/g' server.js
    NODE_OPTIONS="--max-old-space-size=4096 --openssl-legacy-provider" npm run build
EOF

    sleep 2

    banner
    printf " >> Iniciando pm2 frontend...\n"
    echo
    sudo su - deploy <<EOF
    cd /home/deploy/${empresa}/frontend
    pm2 start server.js --name ${empresa}-frontend
    pm2 save
EOF

    sleep 2
  } || trata_erro "instala_frontend_base"
}


# Configura Nginx
config_nginx_base() {
  banner
  printf " >> Configurando nginx frontend...\n"
  echo
  {
    frontend_hostname=$(echo "${subdominio_frontend/https:\/\//}")
    sudo su - root <<EOF
cat > /etc/nginx/sites-available/${empresa}-frontend << 'END'
server {
  server_name ${frontend_hostname};
  location / {
    proxy_pass http://127.0.0.1:${frontend_port};
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_cache_bypass \$http_upgrade;
  }
}
END
ln -s /etc/nginx/sites-available/${empresa}-frontend /etc/nginx/sites-enabled
EOF

    sleep 2

    banner
    printf " >> Configurando Nginx backend...\n"
    echo
    backend_hostname=$(echo "${subdominio_backend/https:\/\//}")
    sudo su - root <<EOF
cat > /etc/nginx/sites-available/${empresa}-backend << 'END'
upstream backend {
        server 127.0.0.1:${backend_port};
        keepalive 32;
    }
server {
  server_name ${backend_hostname};
  location / {
    proxy_pass http://backend;
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
ln -s /etc/nginx/sites-available/${empresa}-backend /etc/nginx/sites-enabled
EOF

    sleep 2

    banner
    printf " >> Emitindo SSL do ${subdominio_backend}...\n"
    echo
    backend_domain=$(echo "${subdominio_backend/https:\/\//}")
    sudo su - root <<EOF
    certbot -m ${email_deploy} \
            --nginx \
            --agree-tos \
            -n \
            -d ${backend_domain}
EOF

    sleep 2

    banner
    printf " >> Emitindo SSL do ${subdominio_frontend}...\n"
    echo
    frontend_domain=$(echo "${subdominio_frontend/https:\/\//}")
    sudo su - root <<EOF
    certbot -m ${email_deploy} \
            --nginx \
            --agree-tos \
            -n \
            -d ${frontend_domain}
EOF

    sleep 2
  } || trata_erro "config_nginx_base"
}


# Ajusta latência - necessita reiniciar a VPS para funcionar de fato
config_latencia_base() {
  banner
  printf " >> Reduzindo Latência...\n"
  echo
  {
    sudo su - root <<EOF
cat >> /etc/hosts << 'END'
127.0.0.1   ${subdominio_backend}
127.0.0.1   ${subdominio_frontend}
END
EOF

    sleep 2

    sudo su - deploy <<EOF
  pm2 restart all
EOF

    sleep 2
  } || trata_erro "config_latencia_base"
}

# Finaliza a instalação e mostra dados de acesso
fim_instalacao_base() {
  banner
  printf "   >> Instalação concluída...\n"
  echo
  printf "   Banckend: ${subdominio_backend}\n"
  printf "   Frontend: ${subdominio_frontend}\n"
  echo
  printf "   Usuário admin@autoatende.com.br\n"
  printf "   Senha   adminpro\n"
  echo
  printf ">> Aperte qualquer tecla para voltar ao menu principal ou CTRL+C Para finalizar esse script\n"
  read -p ""
  echo
}

################################################################
#                         ATUALIZAÇÃO                          #
################################################################




# Adicionar função para instalar transcrição de áudio nativa
instalar_transcricao_audio_nativa() {
  banner
  printf " >> Instalando Transcrição de Áudio Nativa...\n"
  echo
  local script_path="/home/deploy/${empresa}/api_transcricao/install-python-app.sh"
  if [ -f "$script_path" ]; then
    chmod 775 "$script_path"
    bash "$script_path"
  else
    printf " >> Script não encontrado em: $script_path\n"
    sleep 2
  fi
  printf " >> Processo de instalação da transcrição finalizado. Voltando ao menu...\n"
  sleep 2
}

# Adicionar função para instalar API Oficial
instalar_api_oficial() {
  banner
  printf " >> Instalando API Oficial...\n"
  echo
  local script_path="$(pwd)/instalador_apioficial.sh"
  if [ -f "$script_path" ]; then
    chmod 775 "$script_path"
    bash "$script_path"
  else
    printf " >> Script não encontrado em: $script_path\n"
    sleep 2
  fi
  printf " >> Processo de instalação da API Oficial finalizado. Voltando ao menu...\n"
  sleep 2
}

carregar_variaveis
menu
