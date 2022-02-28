#!/usr/bin/env bash
GREEN='\033[0;32m'
NC='\033[0m' # No Color

init_release(){
  if [ -f /etc/os-release ]; then
      # freedesktop.org and systemd
      . /etc/os-release
      OS=$NAME
  elif type lsb_release >/dev/null 2>&1; then
      # linuxbase.org
      OS=$(lsb_release -si)
  elif [ -f /etc/lsb-release ]; then
      # For some versions of Debian/Ubuntu without lsb_release command
      . /etc/lsb-release
      OS=$DISTRIB_ID
  elif [ -f /etc/debian_version ]; then
      # Older Debian/Ubuntu/etc.
      OS=Debian
  elif [ -f /etc/SuSe-release ]; then
      # Older SuSE/etc.
      ...
  elif [ -f /etc/redhat-release ]; then
      # Older Red Hat, CentOS, etc.
      OS="CentOS"
  else
      # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
      OS=$(uname -s)
  fi

  # convert string to lower case
  OS=`echo "$OS" | tr '[:upper:]' '[:lower:]'`

  if [[ $OS = *'ubuntu'* || $OS = *'debian'* ]]; then
    PM='apt'
  elif [[ $OS = *'centos'* ]]; then
    PM='yum'
  else
    exit 1
  fi
}

install_dependency()
{
  init_release
  if [[ $PM = 'apt' ]]; then
    apt install git curl build-essential libssl-dev zlib1g-dev vim-common net-tools telnet -y
  elif [[ $PM = 'yum' ]]; then
    yum install openssl-devel zlib-devel telnet telnet-server net-tools vim-common -y
    yum groupinstall "Development Tools" -y
  fi
}

compile_source()
{
  git --version 2>&1 >/dev/null
  GIT_IS_AVAILABLE=$?
  if [[ $GIT_IS_AVAILABLE -eq 0 ]]; then
    if [[ ! -d "MTProxy" ]]; then
      git clone https://github.com/TelegramMessenger/MTProxy
    fi
    cd MTProxy
    make && cd objs/bin
  else
    $PM install git -y
    compile_source
  fi
}

get_unused_port()
{
  for UNUSED_PORT in $(seq $1 65000); do
    echo -ne "\035" | telnet 127.0.0.1 $UNUSED_PORT > /dev/null 2>&1
    [ $? -eq 1 ] && echo "unused $UNUSED_PORT" && break
  done
}

complete()
{
  IP_ADDRESS=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
  clear
  echo
  echo -e "${GREEN}***************************************************${NR}"
  echo -e "* Server : ${GREEN}${IP_ADDRESS}${NR}"
  echo -e "* Port   : ${GREEN}${SERVER_PORT}${NR}"
  echo -e "* Secret : ${GREEN}${SECRET}${NR}"
  echo -e "${GREEN}***************************************************${NR}"
  echo
  echo -e "Here is a link to your proxy server:\n${GREEN}https://t.me/proxy?server=${IP_ADDRESS}&port=${SERVER_PORT}&secret=${SECRET}${NR}"
  echo
  echo -e "And here is a direct link for those who have the Telegram app installed:\n${GREEN}tg://proxy?server=${IP_ADDRESS}&port=${SERVER_PORT}&secret=${SECRET}${NR}"
  echo -e "${GREEN}***************************************************${NR}"
  echo
}

setup_firewall(){
  if [[ ${PM} = "apt" ]]; then
    ufw allow $SERVER_PORT
  elif [[ ${PM} = "yum" ]]; then
    #statements
    firewall-cmd --zone=public --add-port="$SERVER_PORT"/tcp
    firewall-cmd --zone=public --add-port="$SERVER_PORT"/udp
    firewall-cmd --runtime-to-permanent
  fi
}

main()
{
  install_dependency
  compile_source
  curl -s https://core.telegram.org/getProxySecret -o proxy-secret
  curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf
  clear
  echo
  read -p "Input server port (defalut: Auto Generated):" SERVER_PORT
  if [[ -z ${SERVER_PORT} ]]; then
    get_unused_port 1079
    SERVER_PORT=$UNUSED_PORT
  fi
  read -p "Input secret (defalut: Auto Generated)：" SECRET
  if [[ -z ${SECRET} ]]; then
    SECRET=$(head -c 16 /dev/urandom | xxd -ps)
  fi
  get_unused_port `expr $SERVER_PORT + 1`
  setup_firewall
  nohup ./mtproto-proxy -u nobody -p ${UNUSED_PORT} -H ${SERVER_PORT} -S ${SECRET} --aes-pwd proxy-secret proxy-multi.conf -M 1 &
  complete
}
main
