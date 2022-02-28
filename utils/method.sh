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
  echo $OS
  OS='centos linux'
  OS=`echo "$OS" | tr '[:upper:]' '[:lower:]'`
  echo $OS
  if [[ $OS = *'ubuntu'* || $OS = *'debian'* ]]; then
    pkg='apt'
  elif [[ $OS = *'centos'* ]]; then
    pkg='yum'
  else
    exit 1
  fi
  echo $pkg
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

# check a software has installed
check_in_path(){
  command=$0
  command 2>&1 >/dev/null
  if [[ $? -eq 0 ]]; then
    echo "true"
  else
    echo "false"
  fi
}

stop_firewall(){
  if [[ ${PM} = "apt" ]]; then
    ufw stop
    ufw disable
  elif [[ ${PM} = "yum" ]]; then
    #statements
    systemctl stop firewalld
    systemctl disable firewalld
  fi
}
