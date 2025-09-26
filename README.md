FAZENDO DOWNLOAD DO INSTALADOR & INICIANDO A PRIMEIRA INSTALAÇÃO (USAR SOMENTE PARA PRIMEIRA INSTALAÇÃO):

```bash
sudo apt install -y git && git clone https://github.com/AutoAtende/instalador && sudo chmod -R 777 instalador && cd instalador && sudo chmod -R 775 instalador_apioficial.sh && sudo ./instalador_single.sh
```

Caso for Rodar novamente, apenas execute como root:
```bash 
cd /root/instalador && git reset --hard && git pull &&  sudo chmod -R 775 instalador_single.sh && sudo chmod -R 775 instalador_apioficial.sh &&./instalador_single.sh
```
