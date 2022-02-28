#!/usr/bin/env bash
RED_COLOR='\033[0;31m'
GREEN_COLOR='\033[0;32m'
NO_COLOR='\033[0m'

# script introduction
intro() {
  clear
  echo
  echo "*******************************************************************"
  echo "* System      : CentOS + Debian + Ubuntu                          *"
  echo "* Description : ShadowsocksR Install Script(Support Google BBR)   *"
  echo "* Author      : https://github.com/shellhub                       *"
  echo "*******************************************************************"
  echo
}

# encryption methods
ciphers=(
  table
  rc4
  rc4-md5
  rc4-md5-6
  salsa20
  chacha20
  chacha20-ietf
  aes-256-cfb
  aes-192-cfb
  aes-128-cfb
  aes-256-cfb1
  aes-192-cfb1
  aes-128-cfb1
  aes-256-cfb8
  aes-192-cfb8
  aes-128-cfb8
  aes-256-ctr
  aes-192-ctr
  aes-128-ctr
  bf-cfb
  camellia-128-cfb
  camellia-192-cfb
  camellia-256-cfb
  cast5-cfb
  des-cfb
  idea-cfb
  rc2-cfb
  seed-cfb
  aes-256-gcm
  aes-192-gcm
  aes-128-gcm
  chacha20-ietf-poly1305
  chacha20-poly1305
  xchacha20-ietf-poly1305
)

# Protocol
protocols=(
  origin
  verify_simple
  verify_sha1
  auth_simple
  auth_sha1
  auth_sha1_v2
  auth_sha1_v4
  auth_aes128_md5
  auth_aes128_sha1
  auth_chain_a
  auth_chain_b
)

# Obfuscation
obfuscation=(
  plain
  http_simple
  http_post
  tls1.0_session_auth
  tls1.2_ticket_auth
  tls1.2_ticket_fastauth
)


# current/working directory
CUR_DIR=`pwd`

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
      ...
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
    exit 1 # not support other linux releases
  fi
}

# install dependencies
install_pkg(){
  init_release

  if [[ $PM = 'apt' ]]; then
    apt-get install git -y
    apt-get install dnsutils -y
    apt-get install telnet -y
    apt-get install python2 -y
    apt-get install unzip -y
    apt-get install firewalld -y
  elif [[ $PM = 'yum' ]]; then
    yum install git -y
    yum install bind-utils -y
    yum install telnet -y
    yum install python2 -y
    yum install unzip -y
    yum install firewalld -y
  fi

  stop firewall
  systemctl stop firewalld
  systemctl disable firewalld

  setuptools_url=https://files.pythonhosted.org/packages/68/75/d1d7b7340b9eb6e0388bf95729e63c410b381eb71fe8875cdfd949d8f9ce/setuptools-45.2.0.zip
  file_name=$(basename $setuptools_url)
  dir_name=${file_name%.*}
  if [[ ! -f $file_name ]]; then
    wget -O $file_name $setuptools_url
    unzip $file_name
    # delete zip files
    rm -rf $dir_name.zip
    rm -rf shadowsocksr.sh
  fi
  cd $dir_name

  #install setuptools
  python2 setup.py install
  easy_install pip

  # install qrcode
  pip install qrcode
}

isRoot() {
  if [[ "$EUID" -ne 0 ]]; then
    echo "false"
  else
    echo "true"
  fi
}

get_unused_port()
{
  if [ $# -eq 0 ]
    then
      $1=3333
  fi
  for UNUSED_PORT in $(seq $1 65000); do
    echo -ne "\035" | telnet 127.0.0.1 $UNUSED_PORT > /dev/null 2>&1
    [ $? -eq 1 ] && break
  done
}

config_run(){
  # config password
  read -p "Type password (Default: shellhub):" password
  if [[ -z "$password" ]]; then
    password="shellhub"
  fi
  echo
  echo "-------------------------"
  echo -e "Password = ${GREEN_COLOR}${password}${NO_COLOR}"
  echo "-------------------------"
  echo

  # config server port
  get_unused_port $(shuf -i 2000-65000 -n 1)
  random_port=${UNUSED_PORT}
  read -p "Type port (Default: ${random_port}):" port
  if [[ -z "${port}" ]]; then
    port=${random_port}
  fi
  echo
  echo "-------------------------"
  echo -e "Port = ${GREEN_COLOR}${port}${NO_COLOR}"
  echo "-------------------------"
  echo

  # config encryption method
  while [[ true ]]; do
    for (( i = 0; i < ${#ciphers[@]}; i++ )); do
      echo -e "${GREEN_COLOR}`expr ${i} + 1`${NO_COLOR}:\t${ciphers[${i}]}"
    done
    read -p "Select encryption method (Default: aes-256-cfb):" pick
    if [[ -z ${pick} ]]; then
      # default is aes-256-cfb
      pick=8
    fi
    expr ${pick} + 1 &> /dev/null
    if [[ $? -ne 0 ]]; then
      echo -e "${RED_COLOR}Invalid${NO_COLOR} number ${pick},try again"
      continue
    elif [ ${pick} -lt 1 ] || [ ${pick} -gt ${#ciphers[@]} ]; then
      echo -e "${RED_COLOR}Invalid${NO_COLOR} number ${pick},should be is(1-${#ciphers[@]})"
      continue
    else
      method=${ciphers[${pick}-1]}
      break
    fi
  done

  echo
  echo "-------------------------"
  echo -e "Method = ${GREEN_COLOR}${method}${NO_COLOR}"
  echo "-------------------------"
  echo

  # config protocol
  while [[ true ]]; do
    for (( i = 0; i < ${#protocols[@]}; i++ )); do
      echo -e "${GREEN_COLOR}`expr ${i} + 1`${NO_COLOR}:\t${protocols[${i}]}"
    done
    read -p "Select Protocol (Default: origin):" pick
    if [[ -z ${pick} ]]; then
      # default is origin
      pick=1
    fi
    expr ${pick} + 1 &> /dev/null
    if [[ $? -ne 0 ]]; then
      echo -e "${RED_COLOR}Invalid${NO_COLOR} number ${pick},try again"
      continue
    elif [ ${pick} -lt 1 ] || [ ${pick} -gt ${#ciphers[@]} ]; then
      echo -e "${RED_COLOR}Invalid${NO_COLOR} number ${pick},should be is(1-${#protocols[@]})"
      continue
    else
      ssr_protocol=${protocols[${pick}-1]}
      break
    fi
  done

  echo
  echo "-------------------------"
  echo -e "Protocol = ${GREEN_COLOR}${ssr_protocol}${NO_COLOR}"
  echo "-------------------------"
  echo

  # config obfuscation
  while [[ true ]]; do
    for (( i = 0; i < ${#obfuscation[@]}; i++ )); do
      echo -e "${GREEN_COLOR}`expr ${i} + 1`${NO_COLOR}:\t${obfuscation[${i}]}"
    done
    read -p "Select obfuscation (Default: plain):" pick
    if [[ -z ${pick} ]]; then
      # default is plain
      pick=1
    fi
    expr ${pick} + 1 &> /dev/null
    if [[ $? -ne 0 ]]; then
      echo -e "${RED_COLOR}Invalid${NO_COLOR} number ${pick},try again"
      continue
    elif [ ${pick} -lt 1 ] || [ ${pick} -gt ${#obfuscation[@]} ]; then
      echo -e "${RED_COLOR}Invalid${NO_COLOR} number ${pick},should be is(1-${#obfuscation[@]})"
      continue
    else
      ssr_obfuscation=${obfuscation[${pick}-1]}
      break
    fi
  done

  echo
  echo "-------------------------"
  echo -e "Obfuscation = ${GREEN_COLOR}${ssr_obfuscation}${NO_COLOR}"
  echo "-------------------------"
  echo

  git clone https://github.com/shadowsocksrr/shadowsocksr.git
  cd shadowsocksr/shadowsocks
  nohup python2 server.py -p ${port} -k ${password} -m ${method} -O ${ssr_protocol} -o ${ssr_obfuscation} &
}

enable_bbr(){
  echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
  sysctl -p
  sysctl net.ipv4.tcp_available_congestion_control
  lsmod | grep bbr
}

# show install success information
successInfo(){
  ip_address=$(dig +short myip.opendns.com @resolver1.opendns.com)
  clear
  echo
  echo -e "${GREEN_COLOR}Install successfully, enjoying!!!${NO_COLOR}"
  echo -e "ip:\t\t${GREEN_COLOR}${ip_address}${NO_COLOR}"
  echo -e "port:\t\t${GREEN_COLOR}${port}${NO_COLOR}"
  echo -e "method:\t\t${GREEN_COLOR}${method}${NO_COLOR}"
  echo -e "password:\t\t${GREEN_COLOR}${password}${NO_COLOR}"
  echo -e "protocol:\t\t${GREEN_COLOR}${ssr_protocol}${NO_COLOR}"
  echo -e "obfuscation:\t\t${GREEN_COLOR}${ssr_obfuscation}${NO_COLOR}"
  base64pass=`echo $password | base64`
  remarks="杜远超官方频道"
  base64remarks=`echo $remarks | base64`
  ssr_url="ssr://`echo "$ip_address:$port:$ssr_protocol:$method:$ssr_obfuscation:$base64pass/?remarks=$base64remarks" | base64`"
  echo -e "ssr_url:\t${GREEN_COLOR}${ssr_url}${NO_COLOR}"
  echo
  echo -n $ssr_url | qr
}

main(){
  #check root permission
  isRoot=$( isRoot )
  if [[ "${isRoot}" != "true" ]]; then
    echo "${RED_COLOR}error:${NO_COLOR}Please run this script as as root"
    exit 1
  fi
  install_pkg
  enable_bbr
  intro
  config_run
  successInfo
}

# Script Driver
main
