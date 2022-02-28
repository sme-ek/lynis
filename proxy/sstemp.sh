#!/usr/bin/env bash

RED_COLOR='\033[0;31m'
GREEN_COLOR='\033[0;32m'
NO_COLOR='\033[0m'

# Encryption
ciphers=(
  aes-128-cfb
  aes-192-cfb
  aes-256-cfb
  chacha20
  salsa20
  rc4-md5
  aes-128-ctr
  aes-192-ctr
  aes-256-ctr
  aes-256-gcm
  aes-192-gcm
  aes-128-gcm
  camellia-128-cfb
  camellia-192-cfb
  camellia-256-cfb
  chacha20-ietf
  bf-cfb
)
# current/working directory
CUR_DIR=`pwd`

# script introduction
intro() {
  clear
  echo "*************************************************"
  echo "* OS     : Centos Debian Ubuntu                 *"
  echo "* Desc   : auto install shadowsocks             *"
  echo "* Author : https://github.com/shellhub          *"
  echo "*************************************************"
  echo
}

isRoot() {
  if [[ "$EUID" -ne 0 ]]; then
    echo "false"
  else
    echo "true"
  fi
}

config(){

  # config encryption password
  read -p "Password used for encryption (Default: shellhub):" sspwd
  if [[ -z "${sspwd}" ]]; then
    sspwd="shellhub"
  fi
  echo -e "encryption password: ${GREEN_COLOR}${sspwd}${NO_COLOR}"

  # config server port
  while [[ true ]]; do
    local port=$(shuf -i 2000-65000 -n 1)
    read -p "Server port(1-65535) (Default: ${port}):" server_port
    if [[ -z "${server_port}" ]]; then
      server_port=${port}
    fi

    # make sure port is number
    expr ${server_port} + 1 &> /dev/null
    if [[ $? -eq 0 ]]; then
      # make sure port in range(1-65535)
      if [ ${server_port} -ge 1 ] && [ ${server_port} -le 65535 ]; then
        #make sure port is free
        lsof -i:${server_port} &> /dev/null
        if [[ $? -ne 0 ]]; then
          echo -e "server port: ${GREEN_COLOR}${server_port}${NO_COLOR}"
          break
        else
          echo -e "${RED_COLOR}${server_port}${NO_COLOR} is occupied"
          continue
        fi
      fi
    fi
    echo -e "${RED_COLOR}Invalid${NO_COLOR} port:${server_port}"
  done

  # config encryption method
  while [[ true ]]; do
    for (( i = 0; i < ${#ciphers[@]}; i++ )); do
      echo -e "${GREEN_COLOR}`expr ${i} + 1`${NO_COLOR}:\t${ciphers[${i}]}"
    done
    read -p "Select encryption method (Default: aes-256-cfb):" pick
    if [[ -z ${pick} ]]; then
      # default is aes-256-cfb
      pick=3
    fi
    expr ${pick} + 1 &> /dev/null
    if [[ $? -ne 0 ]]; then
      echo -e "${RED_COLOR}Invalid${NO_COLOR} number ${pick},try again"
      continue
    elif [ ${pick} -lt 1 ] || [ ${pick} -gt ${#ciphers[@]} ]; then
      echo -e "${RED_COLOR}Invalid${NO_COLOR} number ${pick},should be is(1-${#ciphers[@]})"
      continue
    else
      encryption_method=${ciphers[${pick}-1]}
      echo -e "encryption method: ${GREEN_COLOR}${encryption_method}${NO_COLOR}"
      break
    fi
  done
}

getOS(){
  #!/usr/bin/env bash

  if [ -f /etc/os-release ]; then
      # freedesktop.org and systemd
      . /etc/os-release
      OS=$NAME
      VER=$VERSION_ID
  elif type lsb_release >/dev/null 2>&1; then
      # linuxbase.org
      OS=$(lsb_release -si)
      VER=$(lsb_release -sr)
  elif [ -f /etc/lsb-release ]; then
      # For some versions of Debian/Ubuntu without lsb_release command
      . /etc/lsb-release
      OS=$DISTRIB_ID
      VER=$DISTRIB_RELEASE
  elif [ -f /etc/debian_version ]; then
      # Older Debian/Ubuntu/etc.
      OS=Debian
      VER=$(cat /etc/debian_version)
  else
      # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
      OS=$(uname -s)
      VER=$(uname -r)
  fi

  echo ${OS}
  #echo ${VER}
}


containsIgnoreCase(){
  # convert arg1 to lower case
  str=`echo "$1" | tr '[:upper:]' '[:lower:]'`
  # convert arg2 to lower case
  searchStr=`echo "$2" | tr '[:upper:]' '[:lower:]'`

  if [[ ${str} = *${searchStr}* ]]; then
    echo "true"
  else
    echo "false"
  fi
}

#check root permission
isRoot=$( isRoot )

if [[ "${isRoot}" != "true" ]]; then
  echo -e "${RED_COLOR}error:${NO_COLOR}Please run this script as as root"
  exit 1
else
  intro
  config
  os=$( getOS )
  if [[ $( containsIgnoreCase ${os} "ubuntu" ) = "true" ]]; then
    systemPackage="apt-get"
  elif [[ $( containsIgnoreCase ${os} "debian" ) = "true" ]]; then
    systemPackage="apt"
  else
    systemPackage="yum"
  fi
  ${systemPackage} update -y && ${systemPackage} upgrade -y
fi
