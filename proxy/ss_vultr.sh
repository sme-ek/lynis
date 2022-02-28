#!/usr/bin/env bash
enable_bbr(){
  echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
  sysctl -p
  sysctl net.ipv4.tcp_available_congestion_control
}

run_shadowsocks(){
  yum update -y
  #install git
  yum install git -y
  pip3 install  git+https://github.com/shadowsocks/shadowsocks.git@master
  # port="8899"
  # password="112233"
  # encryption="aes-256-cfb"
  ssserver -p $port -k $password -m $encryption --user nobody -d start
  systemctl stop firewalld
  systemctl disable firewalld
}

enable_bbr
run_shadowsocks
